package XAS::Lib::Service::Win32;

our $VERSION = '0.01';

use POE;
use Win32;
use Win32::Daemon;
use Params::Validate;

use WPM::Class
  base     => 'XAS::Lib::Service',
  version  => $VERSION,
  mutators => 'last_state',
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    $self->last_state(SERVICE_START_PENDING);

    unless (Win32::Daemon::StartService()) {

        $self->throw_msg(
            'xas.lib.service.win32.startup.startservice',
            'noservice',
            $self->_get_error()
        );

    }

    $kernel->yield('poll');

}

# ----------------------------------------------------------------------
# Overridden Methods - semi public
# ----------------------------------------------------------------------

sub initialize {
    my ($self, $kernel, $session) = @_;

    $kernel->state('poll', $self, '_poll');

}

sub cleanup {
    my ($self, $kernel, $session) = @_;

    $kernel->delay('poll');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _poll {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $stat;
    my $delay = 0;
    my $state = Win32::Daemon::State();

    $self->log('debug', 'entering _poll()');
    $self->log('debug', "state = $state");

    if ($state == SERVICE_START_PENDING) {

        $self->log('debug', 'state = SERVICE_START_PENDING');

        # Initialization code

        $self->last_state(SERVICE_START_PENDING);
        Win32::Daemon::State(SERVICE_START_PENDING, 6000);

        # Initialization code
        # ...do whatever you need to do to start...

        $self->service_startup();
        $self->last_state(SERVICE_RUNNING);

    } elsif ($state == SERVICE_STOP_PENDING) {

        $self->log('debug', 'state = SERVICE_STOP_PENDING');

        # Stopping...

        $self->service_shutdown();
        $self->last_state(SERVICE_STOPPED);

    } elsif ($state == SERVICE_PAUSE_PENDING) {

        $self->log('debug', 'state = SERVICE_PAUSE_PENDING');

        # Pausing...

        $self->service_paused();
        $self->last_state(SERVICE_PAUSED);

    } elsif ($state == SERVICE_CONTINUE_PENDING) {

        $self->log('debug', 'state = SERVICE_CONTINUE_PENDING');

        # Resuming...

        if ($self->last_state == SERVICE_PAUSED) {

            $self->service_unpaused();
            $self->last_state(SERVICE_RUNNING);

        } else {

            $self->log('info', $self->message('unpaused'));

        }

    } elsif ($state == SERVICE_RUNNING) {

        $self->log('debug', 'state = SERVICE_RUNNING');

        # Running...
        #
        # Note that here you want to check that the state
        # is indeed SERVICE_RUNNING. Even though the Running
        # callback is called it could have done so before
        # calling the "Start" callback.
        #

        if ($self->last_state == SERVICE_RUNNING) {

            $self->service_running();
            $self->last_state(SERVICE_RUNNING);

        }

    } elsif ($state == SERVICE_STOPPED) {

        $self->log('debug', 'state = SERVICE_STOPPED');

        # stopped...

        $delay = $self->poll_interval + 1000;
        $kernel->yield('shutdown');
        $self->last_state(SERVICE_STOPPED);

    } elsif ($state = SERVICE_CONTROL_SHUTDOWN) {

        $self->log('debug', 'state = SERVICE_CONTROL_SHUTDOWN');

        # shutdown...

        $delay = $self->shutdown_interval;
        $self->last_state(SERVICE_STOP_PENDING);

    }

    # tell the scm what is going on...

    Win32::Daemon::State($self->last_state, $delay);

    # queue the next polling interval

    $stat = $kernel->delay('poll', $self->poll_interval);
    $self->log('error', "unable to queue delay - $stat") if ($stat != 0);

    $self->log('debug', 'leaving _poll()');

}

1;

__END__

=head1 NAME

XAS::Lib::Service::Win32 - A base class for Win32 Services using POE

=head1 SYNOPSIS

 use XAS::Lib::Service;

 my $sevice = XAS::Lib::Service::Win32->new(
    -logger            => $log,
    -alias             => 'session',
    -poll_interval     => 2,
    -shutdown_interval => 25
 );

=head1 DESCRIPTION

This module provides an interface between Win32 Services and POE sessions.
It allows POE to manage the scheduling of sessions while referencing the
Win32 SCM event stream.

=head1 METHODS

=head2 new()

This method is used to initialize the service. It takes the following
parameters:

=over 4

=item B<-alias>

The name of this POE session.

=item B<-logger>

This is a session name of the logger.

=item B<-poll_interval>

This is the interval were the SCM sends SERVICE_RUNNING message. The
default is every 2 seconds.

=item B<-shutdown_interval>

This is the interval to pause the system shutdown so that the service
can cleanup after itself. The default is 25 seconds.

=back

It also use parameters from WPM::Lib::Session.

=head2 service_startup()

This method should be overridden, it is called when the service is
starting up.

=head2 service_shutdown()

This method should be overridden, it is called when the service has
been stopped or when the system is shutting down.

=head2 service_running()

This method should be overridden, it is called every B<--poll_interval>.
This is where the work of the service can be done.

=head2 service_paused()

This method should be overridden, it is called when the service has been
paused.

=head2 service_unpaused()

This method should be overridden, it is called when the service has been
resumed.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
