package XAS::Lib::Net::Server;

our $VERSION = '0.03';

use POE;
use Socket;
use Params::Validate;
use POE::Filter::Line;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Session',
  utils     => 'weaken params',
  accessors => 'session',
  constants => 'ARRAY',
  messages => {
      'connection_failed' => "%s: the client connection failed with %s, reason %s",
      'client_error'      => "%s: the client experienced error %s, reason %s",
      'client_connect'    => "%s: a connection from %s on port %s",
      'client_disconnect' => "%s: client disconnected from %s on port %s",
      'recmsg'            => "%s: received message \"%s\" from %s on port %s",
      'reaper'            => "%s: reaper invoked for %s on port %s",
  },
  vars => {
      PARAMS => {
          -port             => 1,
          -inactivity_timer => { optional => 1, default => 600 },
          -filter           => { optional => 1, default => undef },
          -address          => { optional => 1, default => 'localhost' },
      }
  }
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub cleanup {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;
    my $clients = $self->{clients};

    $self->log('debug', "$alias: cleanup()");

    while (my $client = keys %$clients) {

        $kernel->alarm_remove($client->{watchdog});
        $client = undef;

    }

    delete $self->{listener};

}

sub reaper {
    my ($self, $wheel) = @_;

    my $alias = $self->alias;

    $self->log('debug', $self->message('reaper', $alias, $self->host($wheel), $self->peerport($wheel)));

}

# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

sub peerport {
    my ($self, $wheel) = @_;

    return $self->{clients}->{$wheel}->{port};

}

sub host {
    my ($self, $wheel) = @_;

    return $self->{clients}->{$wheel}->{host};
    
}

sub client {
    my ($self, $wheel) = @_;

    return $self->{clients}->{$wheel}->{client};

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub process_request {
    my ($kernel, $self, $input, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $output = $input;

    $kernel->yield('process_response', $output, $ctx);

}

sub process_response {
    my ($kernel, $self, $output, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    $kernel->yield('client_output', $output, $ctx->{wheel});

}

sub process_errors {
    my ($kernel, $self, $output, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    $kernel->yield('client_output', $output, $ctx->{wheel});

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _client_connected {
    my ($kernel, $self, $socket, $peeraddr, $peerport, $wheel_id) = 
      @_[KERNEL,OBJECT,ARG0 .. ARG3];

    my $alias = $self->alias;
    my $inactivity = $self->inactivity_timer;

    $self->log('debug', "$alias: _client_connected()");

    my $client = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Filter     => $self->filter,
        InputEvent => 'client_input',
        ErrorEvent => 'client_error'
    );

    my $wheel = $client->ID;
    my $host = gethostbyaddr($peeraddr, AF_INET);

    $self->{clients}->{$wheel}->{host}   = $host;
    $self->{clients}->{$wheel}->{port}   = $peerport;
    $self->{clients}->{$wheel}->{client} = $client;
    $self->{clients}->{$wheel}->{active} = time();
    $self->{clients}->{$wheel}->{watchdog} = $kernel->alarm_set('client_reaper', $inactivity, $wheel);

    $self->log('info', $self->message('client_connect', $alias, $host, $peerport));

}

sub _client_connection_failed {
    my ($kernel, $self, $syscall, $errnum, $errstr, $wheel) = 
      @_[KERNEL,OBJECT,ARG0 .. ARG3];

    my $alias = $self->alias;

    $self->log('error', $self->message('connection_failed', $alias, $errnum, $errstr));

    delete $self->{listener};

}

sub _client_input {
    my ($kernel, $self, $input, $wheel) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $alias = $self->alias;
    my $ctx = {
        wheel => $wheel
    };

    $self->log('debug', "$alias: _client_input()");

    $self->{clients}->{$wheel}->{active} = time();

    $kernel->yield('process_request', $input, $ctx);

}

sub _client_output {
    my ($kernel, $self, $output, $wheel) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _client_output()");

    $self->{clients}->{$wheel}->{client}->put($output);

}

sub _client_error {
    my ($kernel, $self, $syscall, $errnum, $errstr, $wheel) =
      @_[KERNEL,OBJECT,ARG0 .. ARG3];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _client_error()");

    if ($errnum == 0) {

        $self->log('info', $self->message('client_disconnect', $alias, $self->host($wheel), $self->port($wheel)));

    } else {

        $self->log('error', $self->message('client_error', $alias, $errnum, $errstr));

    }

    delete $self->{clients}->{$wheel};

}

sub _client_reaper {
    my ($kernel, $self, $wheel) = @_[KERNEL,OBJECT,ARG0];

    my $timeout = time() - $self->inactivity_timer;

    if ($self->{clients}->{$wheel}->{active} < $timeout) {

        $self->reaper($wheel);

    }

}

sub _session_init {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_init()");

    # public events

    $kernel->state('process_errors',   $self);
    $kernel->state('process_request',  $self);
    $kernel->state('process_response', $self);

    # private events

    $kernel->state('client_error',             $self, '_client_error');
    $kernel->state('client_input',             $self, '_client_input');
    $kernel->state('client_reaper',            $self, '_client_reaper');
    $kernel->state('client_output',            $self, '_client_output');
    $kernel->state('client_connected',         $self, '_client_connected');
    $kernel->state('client_connection_failed', $self, '_client_connection_failed');

    # call out for other stuff

    $self->initialize($kernel, $session);

    # start listening for connections

    $self->{listener} = POE::Wheel::SocketFactory->new(
        BindAddress    => $self->address,
        BindPort       => $self->port,
        SocketType     => SOCK_STREAM,
        SocketDomain   => AF_INET,
        SocketProtocol => 'tcp',
        Reuse          => 1,
        SuccessEvent   => 'client_connected',
        FailureEvent   => 'client_connection_failed'
    );

    # start everything up

    $kernel->yield('startup');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless (defined($self->filter)) {

        $self->{filter} = POE::Filter::Line->new(
            InputLiteral  => "\012\015",
            OutputLiteral => "\012\015"
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Net::Server - A basic network server for the XAS Environment

=head1 SYNOPSIS

 my $server = XAS::Lib::Net::Server->new(
     -port             => 9505,
     -address          => 'localhost',
     -filter           => POE::Filter::Line->new(),
     -alias            => 'server',
     -inactivity_timer => 600
 }

=head1 DESCRIPTION

This module implements a simple text orientated nework protocol. All "packets" 
will have an explict "\012\015" appended. These packets may be formated strings, 
such as JSON. This module inherits from L<XAS::Lib::Session>.

=head1 METHODS

=head2 new

This initializes the module and starts listening for requests. There are
five parameters that can be passed. They are the following:

=over 4

=item B<-alias>

The name of the POE session.

=item B<-port>

The IP port to listen on.

=item B<-address>

The address to bind too.

=item B<-inactivty_timer>

Sets an inactivity timer on clients. When it is surpassed, the method reaper() 
is called with the POE wheel id. What reaper() does is application specific. 
The default is 600 seconds.

=item B<-filter>

An optional filter to use, defaults to POE::Filter::Line

=back

=head2 reaper($wheel)

Called when the inactivity timer is triggered. 

=over 4

=item B<$wheel>

The POE wheel that triggered the timer.

=back

=head2 declare_events($kernel, $session)

Declare methods to be acted upon.

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$session>

A handle to the current POE session.

=back

=head1 ACCESSORS

=head2 peerport($wheel)

This returns the current port for that wheel.

=over 4

=item B<$wheel>

The POE wheel to use.

=back

=head2 host($wheel)

This returns the current hostname for that wheel.

=over 4

=item B<$wheel>

The POE wheel to use.

=back

=head2 client($wheel)

This returns the current client for that wheel.

=over 4

=item B<$wheel>

The POE wheel to use.

=back

=head1 PUBLIC EVENTS

=head2 process_request($kernel, $self, $input, $ctx)

This event will process the input from the client. It takes the
following parameters:

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$self>

A handle to the current object.

=item B<$input>

The input recieved from the socket.

=item B<$ctx>

A hash variable to maintain context. This will be initialized with a "wheel"
field. Others fields may be added as needed.

=back

=head2 process_response($kernel, $self, $output, $ctx)

This event will process the output from the client. It takes the
following parameters:

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$self>

A handle to the current object.

=item B<$output>

The output to be sent to the socket.

=item B<$ctx>

A hash variable to maintain context. This uses the "wheel" field to direct output
to the correct socket. Others fields may have been added as needed.

=back

=head2 process_errors($kernel, $self, $output, $ctx)

This event will process the error output from the client. It takes the
following parameters:

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$self>

A handle to the current object.

=item B<$output>

The output to be sent to the socket.

=item B<$ctx>

A hash variable to maintain context. This uses the "wheel" field to direct output
to the correct socket. Others fields may have been added as needed.

=back

=head1 SEE ALSO

=over 4

=item POE::Filter::Line

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
