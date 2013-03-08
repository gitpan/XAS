package XAS::Lib::App::Daemon;

our $VERSION = '0.01';

use Try::Tiny;
use File::Pid;
use Pod::Usage;
use Hash::Merge;
use XAS::System;
use Getopt::Long;
use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  import    => 'class CLASS',
  base      => 'XAS::Lib::App',
  utils     => 'daemonize',
  constants => 'TRUE FALSE',
  accessors => 'logfile pidfile daemon',
  messages => {
      'runerr' => '%s is already running: %d',
      'piderr' => '%s has left a pid file behind, exiting',
      'wrterr' => 'unable to create pid file %s',
  },
  vars => {
      script => '',
      PARAMS => {
          -throws   => { optional => 1, default => 'changeme' },
          -options  => { optional => 1, default => [] },
          -facility => { optional => 1, default => 'systems' },
          -priority => { optional => 1, default => 'high' },
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

($script) = ( $0 =~ m#([^\\/]+)$# );

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub define_signals {
    my $self = shift;

    $SIG{'INT'}  = \&signal_handler;
    $SIG{'QUIT'} = \&signal_handler;
    $SIG{'TERM'} = \&signal_handler;
    $SIG{'HUP'}  = \&signal_handler;

}

sub define_logging {
    my $self = shift;

    $self->{log} = XAS::System->module(
        logger => {
            -filename => $self->logfile,
            -debug    => $self->xdebug,
        }
    );

}

sub define_pidfile {
    my $self = shift;

    # create a pid file, use it as a semaphore lock file

    $self->log->debug("entering define_pidfile()");
    $self->log->debug("pid file = " . $self->pidfile);

    try {

        $self->{pid} = File::Pid->new({file => $self->pidfile});
        if ((my $num = $self->pid->running()) || (-e $self->pidfile)){

            if ($num) {

                $self->throw_msg(
                    'xas.lib.app.daemon.pidfile',
                    'runerr',
                    $script, $num
                );

            } else {

                $self->throw_msg(
                    'xas.lib.app.daemon.pidfile',
                    'piderr',
                    $script
                );

            }

        }

        $self->pid->write() or 
          $self->throw_msg(
              'xas.lib.app.daemon.pidfile',
              'wrterr',
              $self->pid->file
          );

    } catch {

        my $ex = $_;

        print STDERR "$ex\n";

        exit 2;

    };

    $self->log->debug("leaving define_pidfile()");

}

sub define_daemon {
    my $self = shift;

    # become a daemon...
    # interesting, "daemonize() if ($self->daemon);" doesn't work as expected

    $self->log->debug("pid = " . $$);

    if ($self->daemon) {

        daemonize();

    }

    $self->log->debug("pid = " . $$);

}

sub run {
    my $self = shift;

    my $rc = $self->SUPER::run();

    $self->pid->remove();

    return $rc;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _class_options {
    my $self = shift;
    
    $self->{pidfile}  = $self->env->pidfile;
    $self->{logfile}  = $self->env->logfile;
    $self->{daemon}   = FALSE;
    $self->{alerts}   = 1;

    return {
        'logfile=s' => \$self->{logfile},
        'pidfile=s' => \$self->{pidfile},
        'daemon'    => \$self->{daemon},
        'debug'     => \$self->{xdebug},
        'alerts!'   => \$self->{alerts},
        'help|h|?'  => sub { pod2usage(-verbose => 0, -exitstatus => 0); },
        'manual'    => sub { pod2usage(-verbose => 2, -exitstatus => 0); },
        'version'   => sub { printf("%s - v%s\n", $script, $self->CLASS->VERSION); exit 0; }
    };

}

1;

__END__

=head1 NAME

XAS::Lib::App::Daemon - The base class to write daemons within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App::Daemon;

 my $app = XAS::Lib::App::Daemon->new();

 $app->run();

=head1 DESCRIPTION

This module defines a base class for writing daemons. It inherits from
XAS::Lib::App. Please see that module for additional documentation.

=head1 METHODS

=head2 define_logging

This method sets up the logger. By default, this file is named 
xas/var/log/<$0>.log. This can be overridden by the --logfile option.

=head2 define_pidfile

This methid sets up the pid file for the process. By default, this file
is named  xas/var/run/<$0>.pid. This can be overridded by the --pidfile option.

=head2 define_signals

This method sets up basic signal handling. By default this is only for the INT, 
TERM, HUP and QUIT signals.

=head2 define_daemon

This method will cause the process to become a daemon.

=head1 ACCESSORS

The following accessors are defined.

=head2 logfile

This returns the currently defined log file. 

=head2 pidfile

This returns the currently defined pid file.

=head1 OPTIONS

This module handles these additional options.

=head2 --logfile

This defines a log file for logging information.

=head2 --pidfile

This defines the pid file for recording the pid.

=head2 --daemon

Become a daemon.

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
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
