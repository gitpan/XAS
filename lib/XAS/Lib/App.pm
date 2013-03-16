package XAS::Lib::App;

our $VERSION = '0.02';

use Try::Tiny;
use Pod::Usage;
use Hash::Merge;
use XAS::System;
use Getopt::Long;
use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  import    => 'class CLASS',
  accessors => 'log alert alerts pid xdebug',
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

sub signal_handler {
    my $signal = shift;

    __PACKAGE__->throw('process intrupted by signal ' . $signal);

}

sub exit_handler {
    my ($self, $ex) = @_;

    my $errors;
    my $rc = 1;
    my $ref = ref($ex);

    if ($ref) {

        if ($ex->isa('XAS::Exception')) {

            my $type = $ex->type;
            my $info = $ex->info;

            $errors = $self->message('exception', $type, $info);

        } else {

            $errors = $self->message('unexpected', $ex);

        }

    } else {

        $errors = $self->message('unknownerror', $ex);

    }

    $self->log->fatal($errors);

    if ($self->alerts) {

        $self->alert->send(
            -priority => $self->priority,
            -facility => $self->facility,
            -message  => $errors
        );

    }

    return $rc;

}

sub define_signals {
    my $self = shift;

    $SIG{'INT'}  = \&signal_handler;
    $SIG{'QUIT'} = \&signal_handler;

}

sub define_logging {
    my $self = shift;

    $self->{log} = XAS::System->module(
        logger => {
            -debug => $self->xdebug,
        }
    );

}

sub define_pidfile {
    my $self = shift;

}

sub define_daemon {
    my $self = shift;

}

sub run {
    my $self = shift;

    my $rc = 0;

    try {

        $self->main();

    } catch {

        my $ex = $_;

        $rc = $self->exit_handler($ex);

    };

    return $rc;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $defaults;
    my $self = $class->SUPER::init(@_);

    class->throws($self->throws);

    $self->_setup();
    $defaults = $self->_class_options();
    $self->_parse_cmdline($defaults, $self->options);

    $self->define_signals();
    $self->define_logging();
    $self->define_daemon();
    $self->define_pidfile();

    return $self;

}

sub _setup {
    my $self = shift;

    # initialize the basic environment

    $self->{alert} = XAS::System->module('alert');

}

sub _class_options {
    my $self = shift;

    $self->{alerts} = 1;

    return {
        'debug'    => \$self->{xdebug},
        'alerts!'  => \$self->{alerts},
        'help|h|?' => sub { pod2usage(-verbose => 0, -exitstatus => 0); },
        'manual'   => sub { pod2usage(-verbose => 2, -exitstatus => 0); },
        'version'  => sub { printf("%s - v%s\n", $script, $self->CLASS->VERSION); exit 0; }
    };

}

sub _parse_cmdline {
    my ($self, $defaults, $params) = @_;

    my $hm = Hash::Merge->new('RIGHT_PRECEDENT');

    my %options;
    my %config;

    foreach my $x (@$params) {

        my ($key, $value) = each(%$x);

        if ($key =~ /^(.*)[|=]/) {

            class->accessors($1);
            $self->{$1} = $value;
            $config{$key} = \$self->{$1};

        } else {

            class->accessors($key);
            $self->{$key} = $value;
            $config{$key} = \$self->{$key};

        }

    }

    %options = %{ $hm->merge($defaults, \%config) };
    GetOptions(%options) or pod2usage(-verbose => 0, -exitstatus => 1);

}

1;

__END__

=head1 NAME

XAS::Lib::App - The base class to write procedures within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App;

 my $app = XAS::Lib::App->new();

 $app->run();

=head1 DESCRIPTION

This module defines a base class for writing procedures. It provides a
logger, signal handling, options processing along with a exit handler.

=head1 METHODS

=head2 new

This method initilaizes the module. It takes several parameters:

=over 4

=item B<-throws>

This changes the default error message from "changeme" to something useful.

=item B<-options>

This will parse additional options from the command line. Those options are
a list of command line options and defaults.

Example 

    my $app = XAS::Lib::App->new(
       -options => [
           { 'logfile=s' => 'test.log' }
       ]
    );

This will then create an accessor named "logfile" that will return the value, 
which may be the supplied default or supplied from the command line.

=item B<-facility>

This will change the facility of the alert. The default is 'systems'.

=item B<-priority>

This will change the priority of the alert. The default is 'high'.

=item B<-alerts>

This will toggle wither to send an alert to the XAS Alert System. The
default is to do so. Values of 'true', 'yes' or 1 will evaluate to TRUE.

=back

=head2 run

This method sets up a global exception handler and calls main(). The main() 
method will be passed one parameter: an initialised handle to this class.

Example

    sub main {
        my $self = shift;

        $self->log->debug('in main');

    }

=over 4

=item Exception Handling

If an exception is caught, the global exception handler will send an alert, 
write the exception to the log and returns an exit code of 1. 

=item Normal Completiion

When the procedure completes successfully, it will return an exit code of 0. 

=back

To change this behavior you would need to override the exit_handler() method.

=head2 define_logging

This method sets up the logger. By default, this logs to stderr. 

Example

    sub define_logging {
        my $self = shift;

        my $logfile = defined($self->logfile) ? 
                              $self->logfile : 
                              $self->env->logfile;

        $self->{log} = XAS::System->module(
            logger => {
                -filename => $logfile,
                -debug    => $debug,
            }
        );

    }

=head2 define_signals

This method sets up basic signal handling. By default this is only for the INT 
and QUIT signals.

Example

    sub define_signals {
        my $self = shift;

        $SIG{INT}  = \&signal_handler;
        $SIG{QUIT} = \&singal_handler;

    }

=head2 signal_handler($signal)

This method is a default signal handler. By default it throws an exception. 
It takes one parameter.

=over 4

=item B<$signal>

The signal that was captured.

=back

=head2 exit_handler($ex)

This method is the default exit handler for any procedure within the XAS 
environment. It will write an entry to the log file and send an alert.

=over 4

=item B<$ex>

This should be an execption object, usually a XAS::Exception. The 
exeception is formated to a string and printed to log.

=back

=head1 ACCESSORS

This module has several accessors that make life easier for you.

=head2 log

This is the handle to the XAS logger.

=head2 alert

This is the handle to the XAS Alert system.

=head2 env

This is the handle to the XAS environment.

=head1 MUTATORS

These mutator are provided to help control the process.

=head2 facility

The facility to use when sending an alert. 

=head2 priority

The priority of the alert. 

=head1 OPTIONS

This module handles the following command line options.

=head2 --debug

This toggles debugging output.

=head2 --[no]alerts

This toggles sending alerts. They are on by default.

=head2 --help

This prints out a short help message based on the procedures pod.

=head2 --manual

This displaces the procedures manual in the defined pager.

=head2 --version

This prints out the version of the module.

=head1 SEE ALSO

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
