package XAS::Lib::Connector;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Class
  version => $VERSION,
  base    => 'POE::Component::Client::Stomp XAS::Base',
  utils   => 'trim',
  messages => {
      connected  => "%s: connected to %s on %s",
      subscribed => "%s: subscribed to %s",
      recverr    => "%s: received an error message: %s",
      recvrpt    => "%s: received a receipt: %s",
      recvmsg    => "%s: received a message #%s",
      received   => "%s: received message #%s of type \"%s\" from %s",
      unknownerr => "%s: %s",
      knownerr   => "%s: %s, %s",
      shutdown   => "%s: shutdown - disconnecting for the server",
      nologger   => "no Logger was defined",
      nologin    => "no Login was defined",
      nopasscode => "no Passcode was defined",
  }
;

use Data::Dumper;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_connection {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    my $alias = $self->config('Alias');

    $self->log($kernel, 'debug', "$alias: entering handle_connection()");

    my $frame = $self->stomp->connect(
        {
            login    => $self->config('Login'),
            passcode => $self->config('Passcode')
        }
    );

    $self->log($kernel, 'info', $self->message('connected', $alias, $self->host, $self->port));

    $kernel->yield('send_data', $frame);
    $kernel->yield('connection_up');

    $self->log($kernel, 'debug', "$alias: leaving handle_connection()");

}

sub handle_receipt {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $alias = $self->config('Alias');
    my $message = $self->message('recvrpt', $alias, $frame->{headers}->{'message-id'});

    $self->log($kernel, 'error', $message);

}

sub handle_error {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $alias = $self->config('Alias');
    my $message = $self->message('recverr', $alias, trim($frame->body));

    $self->log($kernel, 'error', $message);

}

sub handle_message {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $alias = $self->config('Alias');
    my $message = $self->message('recvmsg', $alias, $frame->{headers}->{'message-id'});

    $self->log($kernel, 'error', $message);

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub spawn {
    my $class = shift;

    my %args = @_;
    my $self = $class->SUPER::spawn(@_);

    unless (defined($args{'Logger'})) {

        $self->throw_msg(
            'xas.lib.connector.spawn.nologger',
            'nologger'
        );

    }

    unless (defined($args{'Login'})) {

        $self->throw_msg(
            'xas.lib.connector.spawn.nologin',
            'nologin'
        );

    }

    unless (defined($args{'Passcode'})) {

        $self->throw_msg(
            'xas.lib.connector.spawn.nopasscode',
            'nopasscode'
        );

    }

    return $self;

}

sub log {
    my ($self, $kernel, $level, @args) = @_;

    my $logger = $self->config('Logger');

    $kernel->post($logger, $level, @args);

}

sub handle_shutdown {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->config('Alias');
    my $frame = $self->stomp->disconnect();
    my $message = $self->message('shutdown', $alias);

    $kernel->call($session, 'send_data', $frame);

    $self->log($kernel, 'warn', $message);

}

sub exception_handler {
    my ($self, $ex) = @_;

    my $ref = ref($ex);
    my $alias = $self->config('Alias');

    if ($ref && $ex->isa('XAS::Exception')) {

        my $type = $ex->type;
        my $text = $ex->info;

        $self->log($poe_kernel, 'error', $self->message('knownerr', $alias, $type, $text));

    } else {

        $self->log($poe_kernel, 'error', $self->message('unknownerr', $alias, $ex));

    }

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Connector - Perl extension for the XAS environment

=head1 SYNOPSIS

  use XAS::Lib::Connector;

  my $connection = XAS::Lib::Connector->spawn(
     Logger   => 'logger',
     Login    => 'xas',
     Passcode => 'xas'
  );

=head1 DESCRIPTION

This module is the base class used for connecting to STOMP v1.0 message queue
servers. 

=head1 PUBLIC METHODS

=head2 spawn

This method creates the initial session, and checks for the following
parameters:

=over 

=item B<Logger>

The name of the logging session.

=item B<Login>

The login name to be used on the message queue server.

=item B<Passcode>

The passcode to be used on the message queue server.

=back

=head2 log($kernel, $level, $message)

Provides a logging method for POE::Component::Client::Stomp. 

=over

=item B<$kernel>

A pointer to the POE kernel.

=item B<$level>

A logging level that is compatiable to your logger.

=item B<@args>

The line that is to be written to the log.

=back

=head2 reload($kernel, $session)

This module will handle the HUP signal. It currently executes POE's 
sig_handled() method.

=over

=item B<$kernel>

A pointer to the POE kernel.

=item B<$session>

A point to the current POE session.

=back

=head2 exception_handler($ex)

Provide a default exception handler.

=over

=item B<$ex>

The exception to handle.

=back

=head1 SEE ALSO

 POE::Component::Client::Stomp

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
