package XAS::Supervisor::Controller;

our $VERSION = '0.04';

use POE;
use Set::Light;
use XAS::System;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::RPC::JSON::Server',
  constants => 'TRUE FALSE :jsonrpc :supervisor',
  accessors => 'alert',
  mutators  => 'status',
  messages => {
    starting    => '%s: starting processes',
    started     => '%s: %s has started',
    stopped     => '%s: %s has stopped',
    reloaded    => '%s: %s has reloaded',
    exited      => '%s: %s has exited',
    alive       => '%s: %s is running',
    dead        => '%s: %s is not running',
    nocmd       => "%s: %s's command was not found",
    restart     => '%s: attempting to restart %s',
    retries     => '%s: %s is not running, too many retries',
    checking    => '%s: checking for running sessions',
    killing     => '%s: killing %s',
    stopping    => '%s: stopping %s session',
    shutdown    => '%s: shutting down with the %s signal',
    exit_code   => '%s: exit code: %s, was not recognized for %s. restarting not attempted',
    rpc_unable  => 'xas.supervisor.rpc.%s - unable to "%s" %s',
    rpc_status  => 'xas.supervisor.rpc.%s - %s is %s',
    rpc_dead    => 'xas.supervisor.rpc.%s - %s is not running',
    rpc_nocmd   => "xas.supervisor.rpc.%s - %s's command was not found",
    rpc_retries => 'xas.supervisor.rpc.%s - %s is not running, too many retries',
  },
  vars => {
    PARAMS => {
      -processes => 1
    }
  }
;

# ctx fields and were they come from
#
# $ctx = {
#    id,        - Lib/RPC/JSON/Server.pm
#    wheel,     - Lib/RPC/JSON/Server.pm
#    retries,   - Supervisor/Process.pm
#    error,     - Supervisor/Process.pm
#    name,      - Supervisor/Process.pm
#    timeouts,  - Supervisor/Process.pm
#    status,    - Supervisor/Controller.pm
# }
#

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $ctx = {};
    my $alias = $self->alias;
    my $processes = $self->processes;

    $self->log('info', $self->message('starting', $alias));

    foreach my $process (@$processes) {

        $process->startme($ctx) if ($process->auto_start);

    }

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub interrupt {
    my ($self, $kernel, $session, $signal) = @_;

    my $alias = $self->alias;

    $self->log('warn', $self->message('shutdown', $alias, $signal));

    $kernel->sig_handled();
    $self->status(SHUTDOWN);

    $kernel->yield('shutdown');

}

# ----------------------------------------------------------------------
# Process Events
# ----------------------------------------------------------------------

sub child_started {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $response = $self->message('started', $alias, $ctx->{name});

    $self->log('info', $response);

    if (defined($ctx->{wheel})) {

        $kernel->yield('process_response', $response, $ctx);

    }

}

sub child_stopped {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $response = $self->message('stopped', $alias, $ctx->{name});

    $self->log('info', $response);

    if (defined($ctx->{wheel})) {

        $kernel->yield('process_response', $response, $ctx);

    }

}

sub child_reloaded {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $response = $self->message('reloaded', $alias, $ctx->{name});

    $self->log('info', $response);

    if (defined($ctx->{wheel})) {

        $kernel->yield('process_response', $response, $ctx);

    }

}

sub child_status {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $response = $self->message('rpc_status', $alias, $ctx->{name}, $ctx->{status});

    $self->log('info', $response);

    if (defined($ctx->{wheel})) {

        $kernel->yield('process_response', $response, $ctx);

    }

}

sub child_exited {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $processes = $self->processes;

    $self->log('warn', $self->message('exited', $alias, $ctx->{name}));

    if ($self->status eq SHUTDOWN)  {

        foreach my $process (@$processes) {

            if ($ctx->{name} eq $process->alias) {

                $self->log('info', $self->message('stopping', $alias, $ctx->{name}));
                $kernel->post($process->alias, 'shutdown');
                last;

            }

        }

    } else {

        foreach my $process (@$processes) {

            if ($ctx->{name} eq $process->alias) {

                if ($process->action ne STOP) {

                    if ($process->exit_codes->has($process->exit_code)) {

                        if ($process->auto_restart) {

                            $self->log('info', $self->message('restart', $alias, $ctx->{name}));
                            $process->startme($ctx);

                        }

                    } else {

                        my $code = $process->exit_code || "";
                        my $msg = $self->message('exit_code', $alias, $code, $ctx->{name});

                        $self->log('error', $msg);
                        $kernel->post($process->alias, 'shutdown');

                        $self->alert->send(
                            -message  => $msg, 
                            -facility => $self->facility, 
                            -priority => $self->priority
                        );

                    }
                    last;

                }

            }

        }

    }

}

sub child_error {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $msg;
    my $output;
    my $alias = $self->alias;
    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->alias eq $ctx->{name}) {

            if ($process->action eq START) {

                if ($process->status eq STOPPED) {

                    if ($ctx->{retries} < $process->start_retries) {

                        $process->startme($ctx);

                    } else {

                        $self->log('warn', $self->message('retries', $alias, $process->alias));

                        if (defined($ctx->{wheel})) {

                            $output->{code} = RPC_ERR_APP;
                            $output->{message} = $self->message('rpc_retries', 'child_error', $process->alias);

                            $kernel->yield('process_error', $output, $ctx);

                        }

                    }

                } elsif ($process->status eq DEAD) {

                    if ($ctx->{retries} < $process->start_retries) {

                        $process->startme($ctx);

                    } else {

                        $self->log('warn', $self->message('dead', $alias, $process->alias));

                        if (defined($ctx->{wheel})) {

                            $output->{code} = RPC_ERR_APP;
                            $output->{message} = $self->message('rpc_dead', 'child_error', $process->alias);

                            $kernel->yield('process_error', $output, $ctx);

                        }

                    }

                } elsif ($process->status eq NOCMD) {

                    $self->log('warn', $self->message('nocmd', $alias, $process->alias));

                    if (defined($ctx->{wheel})) {

                        $output->{code} = RPC_ERR_APP;
                        $output->{message} = $self->message('rpc_nocmd', 'child_error', $process->alias);

                        $kernel->yield('process_error', $output, $ctx);

                    }

                }

            } elsif ($process->action eq STOP) {

                if ($process->status eq RUNNING) {

                    if ($ctx->{retries} < $process->stop_retries) {

                        $self->log('warn', $self->message('nocmd', $alias, $process->alias));
                        $process->stopme($ctx);

                    } else {

                        $process->killme($ctx);

                    }

                }

            }

        }

    }

}

# ----------------------------------------------------------------------
# RPC Events
# ----------------------------------------------------------------------

sub stop_process {
    my ($kernel, $self, $params, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $output;
    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->alias eq $params->{name}) {

            $process->stopme($ctx);
            return;

        }

    }

    $output->{code} = RPC_ERR_APP;
    $output->{message} = $self->message('rpc_unable', 'stop_process', 'stop', $params->{name});

    $kernel->yield('process_errors', $output, $ctx);

}

sub stat_process {
    my ($kernel, $self, $params, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $output;
    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->alias eq $params->{name}) {

            $process->statme($ctx);
            return;

        }

    }

    $output->{code} = RPC_ERR_APP;
    $output->{message} = $self->message('rpc_unable', 'stat_process', 'stat', $params->{name});

    $kernel->yield('process_errors', $output, $ctx);

}

sub start_process {
    my ($kernel, $self, $params, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $output;
    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->alias eq $params->{name}) {

            $process->startme($ctx);
            return;

        }

    }

    $output->{code} = RPC_ERR_APP;
    $output->{message} = $self->message('rpc_unable', 'start_process', 'start', $params->{name});

    $kernel->yield('process_errors', $output, $ctx);

}

sub reload_process {
    my ($kernel, $self, $params, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $output;
    my $processes = $self->processes;

    foreach my $process (@$processes) {

        if ($process->alias eq $params->{name}) {

            $process->reloadme($ctx);
            return;

        }

    }

    $output->{code} = RPC_ERR_APP;
    $output->{message} = $self->message('rpc_unable', 'reload_process', 'reload', $params->{name});

    $kernel->yield('process_errors', $output, $ctx);

}

sub stop_supervisor {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $processes = $self->processes;

    $self->status(SHUTDOWN);

    foreach my $process (@$processes) {

        if ($process->status eq STARTED) {

            $process->stopme($ctx);

        }

    }

    $kernel->delay('shutdown', 5);

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub initialize {
    my ($self, $kernel, $session) = @_;

    # communications from the Processes

    $kernel->state('child_error', $self);
    $kernel->state('child_status', $self);
    $kernel->state('child_exited', $self);
    $kernel->state('child_started', $self);
    $kernel->state('child_stopped', $self);
    $kernel->state('child_reloaded', $self);

    # communications with RPC.

    $kernel->state('stop_process', $self);
    $kernel->state('stat_process', $self);
    $kernel->state('start_process', $self);
    $kernel->state('reload_process', $self);
    $kernel->state('stop_supervisor', $self);

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{alert} = XAS::System->module('alert');
    $self->status(RUNNING);

    $self->{methods} = Set::Light->new(qw/
        stop_process 
        start_process 
        stat_process 
        kill_process 
        reload_process 
        stop_supervisor
    /);

    return $self;

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Supervisor::Controller - Controls the XAS Supervisor environment

=head1 SYNOPSIS

 my $supervisor = XAS::Supervisor::Controller->new(
     -alias   => 'supervisor',
     -logger  => 'logger',
     -port    => 9505,
     -address => '127.0.0.1',
     -processes => XAS::Supervisor::Factory->load(
         -cfgfile    => 'supervisor.ini',
         -supervisor => 'supervisor'
    )
 );

 $poe_kernel->run();

=head1 DESCRIPTION

This module is designed to control multiple managed processes. It will attempt
to keep them running. Additionally it will shut them down when the supervisor 
is signalled to stop. The following signals will start the shutdown actions:

=over 4

 INT
 TERM
 HUP
 QUIT
 ABRT

=back

Optionally it can allow external agents access, so that they can interact with 
the managed processes thru a RPC mechaniasm. This module inherits from 
L<XAS::Lib::RPC::JSON::Server|XAS::Lib::RPC::JSON::Server>.

=head2 PARAMETERS

=over 4

=item B<-processes>

The processes that the supervisor will manage.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
