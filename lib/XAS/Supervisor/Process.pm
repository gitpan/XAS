package XAS::Supervisor::Process;

our $VERSION = '0.03';

use POE;
use DateTime;
use Set::Light;
use POE::Wheel::Run;
use Params::Validate;
use POSIX qw(WIFSIGNALED WIFEXITED WEXITSTATUS WTERMSIG :sys_wait_h);

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Lib::Session',
  filesystem => 'FS',
  constants  => ':supervisor',
  mixin      => 'XAS::Lib::Mixin::Env',
  accessors  => 'wheel proc',
  mutators   => 'status action exit_code exit_signal',
  vars => {
    PARAMS => {
      -command         => 1,
      -user            => { optional => 1, default => 'xas' },
      -group           => { optional => 1, default => 'xas' },
      -umask           => { optional => 1, default => '0022' },
      -directory       => { optional => 1, default => '/'},
      -priority        => { optional => 1, default => 0 },
      -start_wait_secs => { optional => 1, default => 10 },
      -start_retries   => { optional => 1, default => 5 },
      -stop_signal     => { optional => 1, default => 'TERM' },
      -stop_wait_secs  => { optional => 1, default => 10 },
      -stop_retries    => { optional => 1, default => 5 },
      -reload_signal   => { optional => 1, default => 'HUP' },
      -auto_start      => { optional => 1, default => 1 },
      -auto_restart    => { optional => 1, default => 1 },
      -supervisor      => { optional => 1, default => 'supervisor' },
      -exit_codes      => { optional => 1, default => '0,1' },
      -environment     => { optional => 1, default => undef }
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

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub startme {
    my ($self, $ctx) = @_;

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering startme()");

    $ctx->{retries} = 1;
    $ctx->{timeouts} = 1;

    if (($self->status eq STOPPED) or ($self->status eq EXITED)) {

        $self->log('info', "$alias: starting process");
        $poe_kernel->post($alias, 'start_process', $ctx);

    } else {

        $ctx->{error} = STARTED;

        $self->log('warn', "$alias: process is already started");
        $poe_kernel->post($supervisor, 'child_error', $ctx);

    }

    $self->log('debug', "$alias: leaving startme()");

}

sub stopme {
    my ($self, $ctx) = @_;

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $ctx->{retries} = 1;
    $self->log('debug', "$alias: entering stopme()");

    if (($self->status eq STARTED) or ($self->status eq RUNNING)) {

        $self->log('info', "$alias: stopping the process");
        $poe_kernel->post($alias, 'stop_process', $ctx);

    } else {

        $self->log('warn', "$alias: process is already stopped");
        $poe_kernel->post($supervisor, 'child_error', $ctx);

    }

    $self->log('debug', "$alias: leaving stopme()");

}

sub reloadme {
    my ($self, $ctx) = @_;

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering reloadme()");

    if ($self->status eq STARTED) {

        $self->log('info', "$alias: sending a \"reload\" signal");
        $poe_kernel->post($alias, 'reload_process', $ctx);

    } else {

        $ctx->{error} = STOPPED;

        $self->log('warn', "$alias: process is stopped");
        $poe_kernel->post($supervisor, 'child_error', $ctx);

    }

    $self->log('debug', "$alias: leaving reloadme()");

}

sub statme {
    my ($self, $ctx) = @_;

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering statme()");
    $self->log('info', "$alias: performing a query status");

    $poe_kernel->post($alias, 'stat_process', $ctx);

    $self->log('debug', "$alias: leaving statme()");

}

sub killme {
    my ($self, $ctx) = @_;

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering killme()");
    $ctx->{retries} = 1;

    if ($self->status eq STARTED) {

        $self->log('info', "$alias: killing the process");
        $poe_kernel->post($alias, 'kill_process', $ctx);

    } else {

        $ctx->{error} = STOPPED;

        $self->log('warn', "$alias: process is already stopped");
        $poe_kernel->post($supervisor, 'child_error', $ctx);

    }

    $self->log('debug', "$alias: leaving killme()");

}

sub cleanup {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;

    $self->log('warn', "$alias: stopping session");

    $kernel->delay('stop_process_timeout');
    $kernel->delay('start_process_timeout');

    if (my $wheel = $self->wheel) {

        delete $self->{wheel};

    }

}

sub interrupt {
    my ($self, $kernel, $session, $signal) = @_;

    my $ctx;
    my $alias = $self->alias;

    $self->log('warn', "$alias: received signal $signal, stopping");
    $self->stopme($ctx);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub initialize {
    my ($self, $kernel, $session) = @_;

    my @exit_codes;

    # public events

    # private events

    $kernel->state('kill_process',          $self, '_kill_process');
    $kernel->state('stop_process',          $self, '_stop_process');
    $kernel->state('stat_process',          $self, '_stat_process');
    $kernel->state('start_process',         $self, '_start_process');
    $kernel->state('reload_process',        $self, '_reload_process');
    $kernel->state('get_stdout',            $self, '_get_stdout');
    $kernel->state('get_stderr',            $self, '_get_stderr');
    $kernel->state('child_exit',            $self, '_child_exit');
    $kernel->state('stop_process_timeout',  $self, '_stop_process_timeout');
    $kernel->state('start_process_timeout', $self, '_start_process_timeout');

    $self->{umask} = oct($self->umask);

    @exit_codes = split(',', $self->exit_codes);

    $self->{exit_codes}  = Set::Light->new(@exit_codes);
    $self->{environment} = env_parse($self->environment);

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _get_stdout {
    my ($kernel, $self, $output, $wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];

    $self->log('info', $output);

}

sub _get_stderr {
    my ($kernel, $self, $output, $wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];

    $self->log('error', $output);

}

sub _child_exit {
    my ($kernel, $self, $exit) = @_[KERNEL,OBJECT,ARG2];

    my $alias       = $self->alias;
    my $supervisor  = $self->supervisor;
    my $exit_code   = WIFEXITED($exit)   ? WEXITSTATUS($exit) : undef;
    my $exit_signal = WIFSIGNALED($exit) ? WTERMSIG($exit)    : undef;
    my $ctx = {
        name => $self->alias
    };

    $self->exit_code($exit_code)     if defined($exit_code);
    $self->exit_signal($exit_signal) if defined($exit_signal);

    $self->log('warn', "$alias: process exited");
    $self->status(EXITED);

    $kernel->post($supervisor, 'child_exited', $ctx);

}

sub _start_process_timeout {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $ctx->{name} = $self->alias;
    $self->log('debug', "$alias: entering _start_process_timeout()");

    if (my $wheel = $self->wheel) {

        $self->log('debug', "$alias: checking for " . $wheel->PID);
        $self->{proc} = FS->dir(PROC_ROOT, $wheel->PID);

        if ($self->proc->exists) {

            $self->log('debug', "$alias: process is alive, telling the supervisor");

            $self->status(STARTED);
            $kernel->sig_child($self->wheel->PID, 'child_exit');
            $kernel->post($supervisor, 'child_started', $ctx);

        } else {

            $self->log('debug', "$alias: process is dead, telling the supervisor");

            $self->status(DEAD);
            $self->{wheel} = undef;
            $kernel->post($supervisor, 'child_error', $ctx);

        }

    } else {

        $self->log('debug', "$alias: process didn't initialize, retrying the start");

        $self->status(DEAD);
        $kernel->post($supervisor, 'child_error', $ctx);

    }

    $self->log('debug', "$alias: leaving _start_process_timeout()");

}

sub _start_process {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;
    my $gid = getgrnam($self->group);
    my $uid = getpwnam($self->user);

    $self->log('debug', "$alias: entering _start_process()");

    $ctx->{name} = $self->alias;
    $self->action(START);

    if ( -f $self->command) {

        if ($ctx->{retries} < $self->start_retries) {

            # save old stuff

            my $oldenv = env_store();
            my $oldmask = umask;
            my $olddir  = FS->cwd();

            # create new stuff

            umask $self->umask;
            chdir $self->directory;
            env_create($self->environment);

            # spawn the process

            $self->{wheel} = POE::Wheel::Run->new(
                StderrEvent => 'get_stderr',
                StdoutEvent => 'get_stdout',
                Group       => $gid,
                User        => $uid,
                Priority    => $self->priority,
                Program     => $self->command
            );

            # restore old stuff

            env_restore($oldenv);
            umask $oldmask;
            chdir $olddir;

            # see if it worked...

            $ctx->{retries}++;
            $self->log('info', "$alias: pid = " . $self->wheel->PID);
            $kernel->delay('start_process_timeout', $self->start_wait_secs, $ctx);

        } else {

            $self->log('debug', "$alias: to many retries");

            $self->status(STOPPED);
            $self->{wheel} = undef;
            $kernel->post($supervisor, 'child_error', $ctx);

        }

    } else {

        $self->log('debug', "$alias: command doesn't exist");

        $self->status(NOCMD);
        $self->{wheel} = undef;
        $kernel->post($supervisor, 'child_error', $ctx);

    }

    $self->log('debug', "$alias: leaving _start_process()");

}

sub _stop_process_timeout {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering _stop_process_timeout()");
    $ctx->{retries}++;

    if (my $wheel = $self->wheel) {

        unless ($self->proc->exists) {

            $self->log('debug', "$alias: process is dead, telling the supervisor");

            $self->status(STOPPED);
            $kernel->post($supervisor, 'child_stopped', $ctx);

        } else {

            $self->log('debug', "$alias: process is still alive, retrying the stop");

            $self->status(RUNNING);
            $kernel->post($supervisor, 'child_error', $ctx);

        }

    } else {

        $self->log('debug', "$alias: process is gone, telling the supervisor");

        $self->status(STOPPED);
        $kernel->post($supervisor, 'child_stopped', $ctx);

    }

    $self->log('debug', "$alias: leaving _stop_process_timeout()");

}

sub _stop_process {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering _stop_process()");
    $ctx->{name} = $self->alias;
    $self->action(STOP);

    if ($ctx->{retries} < $self->stop_retries) {

        $self->log('debug', "$alias: sending stop signal");

        $ctx->{retries}++;
        kill($self->stop_signal, $self->wheel->PID);
        $kernel->delay('stop_process_timeout', $self->stop_wait_secs, $ctx);

    } else {

        $self->log('debug', "$alias: to many retries");

        $self->status(STOPPED);
        delete $self->{wheel};

        $ctx->{status} = $self->status;
        $kernel->post($supervisor, 'child_error', $ctx);

    }

    $self->log('debug', "$alias: leaving _stop_process()");

}

sub _kill_process {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering _kill_process()");
    $ctx->{name} = $self->alias;

    if ($ctx->{retries} < $self->stop_retries) {

        $self->log('debug', "$alias: sending kill signal");

        $ctx->{retries}++;
        kill(9, $self->wheel->PID);
        $kernel->delay('stop_process_timeout', $self->stop_wait_secs, $ctx);

    } else {

        $self->log('debug', "$alias: to many retries");

        $self->status(STOPPED);
        delete $self->{wheel};

        $ctx->{status} = $self->status;
        $kernel->post($supervisor, 'child_error', $ctx);

    }

    $self->log('debug', "$alias: leaving _kill_process()");

}

sub _reload_process {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering _reload_process()");
    $ctx->{name} = $self->alias;

    $self->log('debug', "$alias: sending reload signal");

    $self->action(RELOAD);
    $self->status(RELOADED);

    if (kill($self->reload_signal, $self->wheel->PID)) {

        $kernel->post($supervisor, 'child_reloaded', $ctx);

    }

    $self->log('debug', "$alias: leaving _reload_process()");

}

sub _stat_process {
    my ($kernel, $self, $ctx) = @_[KERNEL,OBJECT,ARG0];

    my $alias = $self->alias;
    my $supervisor = $self->supervisor;

    $self->log('debug', "$alias: entering _stat_process()");
    $ctx->{name} = $self->alias;

    $self->action(STAT);

    if ($self->proc->exists) {

        $self->log('debug', "$alias: process is alive");

        $ctx->{status} = ALIVE;
        $kernel->post($supervisor, 'child_status', $ctx);

    } else {

        $self->log('debug', "$alias: process is dead");

        $ctx->{status} = DEAD;
        $kernel->post($supervisor, 'child_status', $ctx);

    }

    $self->log('debug', "$alias: leaving _stat_process()");

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->status(STOPPED);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Supervisor::Process - Defines a managed process for the Supervisor environment

=head1 SYNOPSIS

A managed process is defined and started as follows:

 my $process = XAS::Supervisor::Process->new(
    -alias           => 'sleeper',
    -command         => 'sleeper.sh',
    -umask           => '0022',
    -user            => 'kesteb',
    -group           => 'users',
    -directory       => '/',
    -priority        => 0,
    -start_wait_secs => 10,
    -start_retries   => 5,
    -stop_signal     => 'TERM',
    -stop_wait_secs  => 10,
    -stop_retries    => 5,
    -reload_signal   => 'HUP',
    -auto_start      => TRUE,
    -auto_restart    => TRUE,
    -supervisor      => 'controller',
    -exit_codes      =>  '0,1',
    -environment     => 'item=value;;item2=value2'
 );

 $process->startme($ctx);

=head1 DESCRIPTION

A managed process is an object that knows how to start/stop/reload and 
return the status of that process. How the object knows what to do, is
defined by the parameters that are set when the object is created. Those
parameters are as follows.

=head1 PARAMETERS

=head2 B<-alias>

The name the process is know by. A string value.

=head2 B<-command>

The command to run within the process. A string value.

=head2 B<-user>

The user context the run the process under. No effort is made to check if the 
user actually exists. A string value.

=head2 B<-group>

The group context to run the process under. No effort is made to check if the 
group actually exists. A string value.

=head2 B<-umask>

The umask for this process. A string value.

=head2 B<-directory>

The directory to set default too when running the process. No effort is made
to make sure the directory is valid. A string value.

=head2 B<-priority>

The priority to run the process at. An integer value.

=head2 B<-start_retries>

The number of retires when trying to start the process. An integer value.

=head2 B<-start_wait_secs>

The number of seconds to wait between attempts to start the process. An integer
value.

=head2 B<-stop_signal>

The signal to send when trying to stop the process. A string value. It should
be in a format that Perl understands.

=head2 B<-stop_retries>

How many times to try and stop the process before issuing a KILL signal. An 
integer value.

=head2 B<-stop_wait_secs>

The number of seconds to wait between attempts to stop the process. A intger value.

=head2 B<-reload_signal>

The signal to use to attempt a "reload" on the process. A string value. It 
should in a format that Perl understands.

=head2 B<-auto_start>

Wither the process should be auto started by a supervisor. A boolean value.

=head2 B<-auto_restart>

Wither to attempt to restart the process should it unexpectedly exit. A 
boolean value.

=head2 B<-supervisor>

The session name of a controlling supervisor. A string value.

=head2 B<-exit_codes>

The expected exit codes from the process. If a returned exit code does not
match this list, the process will not be restarted. This should be a comma 
delimited list of integers. 

=head2 B<-environment>

The environment variables for the process. This is a formated string. The 
format should be a double semi-colon delimited string of name/value pairs.

=head1 METHODS

In the following methods the $ctx parameter is used to hold context. It should
not be directly manipulated.

=head2 startme($ctx)

This method will start the process running. Will return "start" if successful.

=head2 stopme($ctx)

This method will stop the process. Will return "stop" if successful.

=head2 statme($ctx)

This method will perform a "stat" on the process. It will return either 
"alive" or "dead".

=head2 reloadme($ctx)

This method will send a signal to the process to "reload".

=head2 killme($ctx)

This method will send a KILL signal to the process.

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
