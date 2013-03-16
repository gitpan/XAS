package XAS::Lib::Net::Server;

our $VERSION = '0.02';

use POE;
use Socket;
use Params::Validate;
use POE::Filter::Line;
use POE::Wheel::ReadWrite;
use POE::Wheel::SocketFactory;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'weaken params',
  accessors => 'session',
  messages => {
      'connection_failed' => "%s: the client connection failed with %s, reason %s",
      'client_error'      => "%s: the client experienced error %s, reason %s",
      'client_connect'    => "%s: a connection from %s on port %s",
      'client_disconnect' => "%s: client disconnected from %s on port %s",
      'alias'             => '%s: unable to set session alias',
      'recmsg'            => "%s: received message \"%s\" from %s on port %s",
      'reaper'            => "%s: reaper invoked for %s on port %s",
  },
  vars => {
      PARAMS => {
          -port             => 1,
          -inactivity_timer => { optional => 1, default => 600 },
          -filter           => { optional => 1, default => undef },
          -logger           => { optional => 1, default => 'logger' },
          -alias            => { optional => 1, default => 'server' },
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

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub initialize {
    my ($self, $kernel) = @_;

}

sub reload {
    my ($self, $kernel, $session) = @_;

}

sub shutdown {
    my ($self, $kernel, $session) = @_;

}

sub process {
    my ($self, $message, $wheel) = @_;

    my $alias = $self->alias;
    
    $self->log('info', $self->message('recmsg', $alias, $message, $self->host($wheel), $self->peerport($wheel)));

    return $message;

}

sub reaper {
    my ($self, $wheel) = @_;

    my $alias = $self->alias;

    $self->log('debug', $self->message('reaper', $alias, $self->host($wheel), $self->peerport($wheel)));

}

sub log {
    my ($self, $level, $message) = @_;

    my $logger = $self->logger;

    $poe_kernel->post($logger, $level, $message);

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

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_start {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_start()");

    # set the sessions alias

    if ((my $rc = $kernel->alias_set($alias)) > 0) {

        $self->throw_msg(
            'xas.lib.net.server.alias',
            'alias'
        );

    }

    # set up signal handling

    $kernel->sig(HUP  => 'session_interrupt');
    $kernel->sig(INT  => 'session_interrupt');
    $kernel->sig(TERM => 'session_interrupt');
    $kernel->sig(QUIT => 'session_interrupt');

    # perform other initialization

    $self->initialize($kernel);

    # start the server

    $kernel->yield('server_start');

}

sub _session_stop {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_stop()");

    if (defined($self->{listener})) {

        delete $self->{listener};

    }

    $kernel->alias_remove($alias);

}

sub _session_reload {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_reload()");

    $self->reload($kernel, $session);

}

sub _session_interrupt {
    my ($kernel, $self, $session, $signal) = @_[KERNEL,OBJECT,SESSION,ARG0];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_interrupt()");

    if ($signal eq 'HUP') {

        $self->reload($kernel, $session);

    } else {

        $self->shutdown($kernel, $session);

    }

}

sub _session_shutdown {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $alias = $self->alias;
    my $clients = $self->{clients};

    $self->log('debug', "$alias: _session_shutdown()");

    $self->shutdown($kernel, $session);

    while (my $wheel = keys %$clients) {

        $kernel->alarm_remove($self->{clients}->{$wheel}->{watchdog});
        delete $self->{clients}->{$wheel};

    }

}

sub _server_start {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _server_start()");

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

}

sub _client_connected {
    my ($kernel, $self, $socket, $peeraddr, $peerport, $wheel_id) = 
      @_[KERNEL,OBJECT,ARG0 .. ARG3];

    my $alias = $self->alias;
    my $inactivity = $self->inactivity_timer;

    $self->log('debug', "$alias: _client_connected()");

    my $client = POE::Wheel::ReadWrite->new(
        Handle     => $socket,
        Filter     => $self->filter,
        InputEvent => 'client_message',
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

sub _client_message {
    my ($kernel, $self, $input, $wheel) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _client_message()");

    $self->{clients}->{$wheel}->{active} = time();

    my $output = $self->process($input, $wheel);

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

    $self->{session} = POE::Session->create(
        object_states => [
            $self => {
                _start                   => '_session_start',
                _stop                    => '_session_stop',
                shutdown                 => '_session_shutdown',
                session_interrupt        => '_session_interrupt',
                session_reload           => '_session_reload',
                server_start             => '_server_start',
                client_error             => '_client_error',
                client_reaper            => '_client_reaper',
                client_message           => '_client_message',
                client_connected         => '_client_connected',
                client_connection_failed => '_client_connection_failed'
            }
        ]
    );

    weaken($self->{session});

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
such as JSON. The server runs as a POE session.

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

=head2 initialize($kernel)

This method is for specific initialization of the module. By default it does
nothing.

=over 4

=item B<$kernel>

A handle for the POE kernel

=back

=head2 reload($kernel, $session)

This method runs when a HUP signal is recieved. By default if does nothing.

=over 4

=item B<$kernel>

A handle for the POE kernel.

=item B<$session>

A handle to the current POE session.

=back

=head2 shutdown($kernel, $session)

This method starts the "shutdown" process for the POE session. A "shutdown" 
can be initiated by an INT, TERM or QUIT signal. By default it does nothing. 

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$session>

A handle to the current POE session.

=back

=head2 reaper($wheel)

Called when the inactivity timer is triggered. 

=over 4

=item B<$wheel>

The POE wheel that triggered the timer.

=back

=head2 process($packet, $wheel)

This method does the processing for any packets that are sent over the socket.
By default, it just returns the packet.

=over 4

=item B<$packet>

The packet that was sent over the socket.

=item B<$wheel>

The POE wheel that handled the packet.

=back

=head2 log($level, $message)

This will write log messages. The default this is just a dump to stderr.

=over 4

=item B<$level>

The log level, this is usually INFO, WARN, ERROR, FATAL or DEBUG. These
are the levels that are understood by the XAS logger.

=item B<$message>

The message to log.

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

=head1 SEE ALSO

 POE::Filter::Line

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
