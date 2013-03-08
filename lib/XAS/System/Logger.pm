package XAS::System::Logger;

our $VERSION = '0.01';

use DateTime;

use XAS::Class
  version    => $VERSION,
  base       => 'Badger::Log',
  throws     => 'xas.system.logger',
  utils      => 'blessed',
  import     => 'class',
  constants  => 'ARRAY CODE',
  config     => 'system|class:SYSTEM format|class:FORMAT filename|class:FILENAME',
  filesystem => 'File',
  constant => {
      MSG => '_msg',
      LOG => 'log'
  },
  vars => {
      FILENAME => 'stderr',
      SYSTEM   => 'XAS',
      FORMAT   => "[<time>] <level> - <message>",
      LEVELS => {
          debug => 0,
          info  => 1,
          warn  => 1,
          error => 1,
          fatal => 1
     }
  },
  messages => {
      invperms  => "unable to change file permissions on %s",
      creatfile => "unable to create file %s"
  }
;

use Data::Dumper;

class->methods(
    # Our init method is called init_log() so that we can use Badger::Log as 
    # a mixin or base class without worrying about the init() method clashing 
    # with init() methods from other base classes or mixins.  We create an 
    # alias from init() to init_log() so that it also Just Works[tm] as a 
    # stand-alone object

    init => \&init_log,

    # Now we define two methods for each logging level.  The first expects
    # a pre-formatted output message (e.g. debug(), info(), warn(), etc)
    # the second additionally wraps around the message() method inherited
    # from Badger::Base (eg. debug_msg(), info_msg(), warn_msg(), etc)

    map {
        my $level = $_;             # lexical variable for closure
        
        $level => sub {
            my $self = shift;
            return $self->{ $level } unless @_;
            $self->log($level, @_) 
                if $self->{ $level };
        },

        ($level.MSG) => sub {
            my $self = shift;
            return $self->{ $level } unless @_;
            $self->log($level, $self->message(@_)) 
                if $self->{ $level };
        }
    }
    keys %$LEVELS
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub format {
    my $self = shift;

    my $dt = DateTime->now(time_zone => 'local');
    my $args = {
      time    => sprintf("%s %s", $dt->ymd('-'), $dt->hms),
      system  => $self->{system},
      level   => sprintf("%-5s", uc(shift)),
      message => shift,
    };

    my $format = $self->{format};

    $format =~ 
        s/<(\w+)>/
        defined $args->{ $1 } 
            ? $args->{ $1 }
            : "<$1>"
            /eg;

    return $format;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_log {
    my ($self, $config) = @_;

    # strip leading '-' from config variables

    while (my ($key, $value) = each %$config) {

        delete $config->{$key};

        $key =~ s/^-//g;
        $config->{$key} = $value;

    }

    my $class  = $self->class;
    my $levels = $class->hash_vars( LEVELS => $config->{ levels } );

    # populate $self for each level in $LEVEL using the
    # value in $config, or the default in $LEVEL
    
    while (my ($level, $default) = each %$levels) {
        $self->{ $level } =
          defined $config->{ $level }
          ? $config->{ $level }
          : $levels->{ $level };
    }

    # call the auto-generated configure() method to update $self from $config

    $self->configure($config);

    # make a Badger::Filesystem::File object.

    $self->{filename} = File($self->{filename});

    # if a filename exists, initialize the file and redirect to it

    if ((my $filename = $self->{filename}->path) and ($self->{filename}->name !~ /^stderr$/i )) {

        # check to see if file exists, otherwise create it

        unless ( -e $filename ) {

            if (my $fh = $self->{filename}->open('>')) {

                $fh->close;

            } else {

                $self->_error_msg('creatfile', $filename);

            }

        }

        if ($^O ne "MSWin32") {

            my ($cnt, $mode, $permissions);

            # set file permissions

            $mode = (stat($filename))[2];
            $permissions = sprintf("%04o", $mode & 07777);

            if ($permissions ne "0664") {

                $cnt = chmod(0664, $filename);
                $self->_error_msg('invperms', $filename) if ($cnt < 1);

            }

        }

    }

    return $self;

}

sub log {
    my $self    = shift;
    my $level   = shift;
    my $action  = $self->{ $level };
    my $message = join('', @_);
    my $method;

    return $self->_fatal_msg( bad_level => $level )
              unless defined $action;

    # depending on what the $action is set to, we add the message to
    # an array, call a code reference, delegate to another log object,
    # print or ignore the mesage

    if (ref $action eq ARRAY) {

        push(@$action, $message);

    } elsif (ref $action eq CODE) {

        &$action($level, $message);

    } elsif (blessed $action && ($method = $action->can(LOG))) {

        $method->($action, $level, $message);

    } elsif ($action) {

        if ($self->{filename}->name eq 'stderr') {

            warn $self->format($level, $message) . "\n";

        } else {

            $self->{filename}->append($self->format($level, $message) . "\n");

        }

    }

}

1;

__END__

=head1 NAME

XAS::System::Logger - The logging module for the XAS environment

=head1 SYNOPSIS

Your program could use this module in the following fashion:

 use XAS::System;

 $log = XAS::System->module(
      logger => {
          -filename => 'test.log',
          -debug => TRUE,
      }
 );

 $log->info("Hello world!");

 or ...

 use XAS::System;

 $ddc = XAS::System->module('environment');
 $log = XAS::System->module(
      logger => {
          -filename => $ddc->logfile,
          -debug    => TRUE,
      }
 );

 $log->info("Hello world!");

 or ...

 $log = XAS::System->module('logger');

 $log->info("Hello world");

=head1 DESCRIPTION

This is the the module for logging within the XAS environment, it is a 
wrapper around Badger::Log. You should read the documentation for that 
module to learn all the options that are available.

This module provides an extension that allows all options to have
a leading dash. This is to be consistent with the rest of the XAS modules. It
will also set the correct file permissions on the log files so they can be
interchanged within the environment.

By default, the following log levels are active:

    info
    warn
    error
    fatal

By default, output will be sent to stderr.

=head1 ACCESSORS

=head2 filename

This accessor will return the name of the current log file.

Example

     $filename = $log->filename;

=head1 SEE ALSO

 Badger::Log

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
