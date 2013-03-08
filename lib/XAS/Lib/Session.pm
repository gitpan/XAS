package XAS::Lib::Session;

our $VERSION = '0.04';

use POE;
use Params::Validate;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'weaken',
  accessors => 'session',
  messages => {
      noalias    => "can not set session alias %s",
  },
  vars => {
      PARAMS => {
          -alias => { optional => 1, default => 'session' },
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

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub cleanup {
    my ($self, $kernel, $session) = @_;

}

sub initialize {
    my ($self, $kernel, $session) = @_;

}

sub log {
    my ($self, $level, $message) = @_;

    warn sprintf("%-5s - %s\n", uc($level), $message);

}

sub reload {
    my ($self, $kernel, $session) = @_;

    $kernel->sig_handled();

}

sub stop {
    my ($self, $kernel, $session) = @_;

}

# ----------------------------------------------------------------------
# Public Accessors
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;
    
    my $self = $class->SUPER::init(@_);

    $self->{session} = POE::Session->create(
        object_states => [
            $self => {
                _start            => '_session_start',
                _stop             => '_session_stop',
                session_init      => '_session_init',
                session_interrupt => '_session_interrupt',
                session_reload    => '_session_reload',
                shutdown          => '_session_shutdown',
            },
            $self => [qw( startup )]
        ]
    );

    weaken($self->{session});

    return $self;

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _session_start {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_start()");

    if ((my $rc = $kernel->alias_set($alias)) > 0) {

        $self->throw_msg(
            'xas.session._session_start.noalias', 
            'noalias', 
            $alias
        );

    }

    $kernel->sig(HUP  => 'session_interrupt');
    $kernel->sig(INT  => 'session_interrupt');
    $kernel->sig(TERM => 'session_interrupt');
    $kernel->sig(QUIT => 'session_interrupt');

    $kernel->yield('session_init');

}

sub _session_stop {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    $self->stop($kernel, $session);

    $kernel->alias_remove($self->alias);

}

sub _session_shutdown {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_shutdown()");

    $self->cleanup($kernel, $session);

}

sub _session_reload {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_reload()");

    $self->reload($kernel, $session);

}

sub _session_init {
    my ($kernel, $self, $session) = @_[KERNEL,OBJECT,SESSION];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_init()");
    $self->initialize($kernel, $session);

    $kernel->yield('startup');

}

sub _session_interrupt {
    my ($kernel, $self, $session, $signal) = @_[KERNEL,OBJECT,SESSION,ARG0];

    my $alias = $self->alias;

    $self->log('debug', "$alias: _session_interrupt()");

    if ($signal eq 'HUP') {

        $self->reload($kernel, $session);

    } else {

        $self->cleanup($kernel, $session);

    }

}

1;

__END__

=head1 NAME

XAS::Lib::Session - The base class for all POE Sessions.

=head1 SYNOPSIS

 my $session = XAS::Lib::Session->new(
     Alias => 'name',
 );

=head1 DESCRIPTION

This module provides an object based POE session. This object will perform
the necessary actions for the lifetime of the session. This includes handling
signals. The following signals INT, TERM, QUIT will trigger the 'shutdown' 
event which invokes the cleanup() method. The HUP signal will invoke the 
reload() method.

=head1 METHODS

=head2 initialize($kernel, $session)

This is where the session should do whatever initialization it needs. This 
initialization may include defining additional events. 

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$session>

A handle to the current POE session.

=back

=head2 cleanup($kernel, $session)

This method should perform cleanup actions for the session. This is triggered
by a "shutdown" event.

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$session>

A handle to the current POE session.

=back

=head2 reload($kernel, $session)

This method should perform reload actions for the session. By default it
calls $kernel->sig_handled() which terminates further handling of the HUP
signal. 

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$session>

A handle to the current POE session.

=back

=head2 stop($kernel, $session)

This method should perform stop actions for the session. This is triggered
by a "_stop" event.

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$session>

A handle to the current POE session.

=back

=head2 config($item)

This method will return a value from the configuration items for this object. 
It is passed one parameter, the name of the config item.

=over 4

=item B<$item>

Return the value for this item from the config.

Example:

    my $item = $self->config('Item');

=back

=head2 log($level, $message)

This method provides a simple logger. It should be overridden.

=over

=item B<$level>

A log level that is compatiable with your logger.

=item B<$message>

The message to write in the log.

=back

=head1 PUBLIC EVENTS

The following public events are defined for the session.

=head2 startup($kernel, $self)

This event should start whatever processing the session will do. It is passed
two parameters:

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$self>

A handle to the current self.

=back

=head2 shutdown

When you send this event to the session, it will invoke the cleanup() method.

=head1 PRIVATE EVENTS

The following events are used internally:

 session_init
 session_interrupt
 session_reload
 shutdown

They should only be used with caution.

=head1 SEE ALSO

 XAS::Base
 XAS::Class
 XAS::Constants
 XAS::Exception
 XAS::System
 XAS::Utils

 XAS::Apps::Base::Alerts
 XAS::Apps::Base::Collector
 XAS::Apps::Base::ExtractData
 XAS::Apps::Base::ExtractGlobals
 XAS::Apps::Base::RemoveData
 XAS::Apps::Database::Schema
 XAS::Apps::Templates::Daemon
 XAS::Apps::Templates::Generic
 XAS::Apps::Test::Echo::Client
 XAS::Apps::Test::Echo::Server
 XAS::Apps::Test::RPC::Client
 XAS::Apps::Test::RPC::Methods
 XAS::Apps::Test::RPC::Server

 XAS::Collector::Alert
 XAS::Collector::Base
 XAS::Collector::Connector
 XAS::Collector::Factory

 XAS::Lib::App
 XAS::Lib::App::Daemon
 XAS::Lib::App::Daemon::POE
 XAS::Lib::Connector
 XAS::Lib::Counter
 XAS::Lib::Daemon::Logger
 XAS::Lib::Daemon::Logging
 XAS::Lib::Gearman::Admin
 XAS::Lib::Gearman::Admin::Status
 XAS::Lib::Gearman::Admin::Worker
 XAS::Lib::Gearman::Client
 XAS::Lib::Gearman::Client::Status
 XAS::Lib::Gearman::Worker
 XAS::Lib::Net::Client
 XAS::LIb::Net::Server
 XAS::Lib::RPC::JSON::Client
 XAS::Lib::RPC::JSON::Server
 XAS::Lib::Session
 XAS::Lib::Spool

 XAS::Model::Database
 XAS::Model::Database::Alert
 XAS::Model::Database::Counter
 XAS::Model::DBM

 XAS::Monitor::Base
 XAS::Monitor::Database
 XAS::Monitor::Database::Alert

 XAS::Scheduler::Base

 XAS::System::Alert
 XAS::System::Email
 XAS::System::Environment
 XAS::System::Logger

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
