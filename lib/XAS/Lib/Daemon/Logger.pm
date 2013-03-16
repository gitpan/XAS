package XAS::Lib::Daemon::Logger;

our $VERSION = '0.02';

use POE;
use Params::Validate;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Session',
  accessors => 'log',
  vars => {
      PARAMS => {
          -logger => 1,
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

sub debug {
    my ($kernel, $self, $buffer) = @_[KERNEL,OBJECT,ARG0];

    $self->log->debug($buffer);

};

sub info {
    my ($kernel, $self, $buffer) = @_[KERNEL,OBJECT,ARG0];

    $self->log->info($buffer);

}

sub warn {
    my ($kernel, $self, $buffer) = @_[KERNEL,OBJECT,ARG0];

    $self->log->warn($buffer);

}

sub error {
    my ($kernel, $self, $buffer) = @_[KERNEL,OBJECT,ARG0];

    $self->log->error($buffer);

}

sub fatal {
    my ($kernel, $self, $buffer) = @_[KERNEL,OBJECT,ARG0];

    $self->log->fatal($buffer);

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub initialize {
    my ($self, $kernel, $session) = @_;

    my $log = $self->logger;
    my $alias = $self->alias;

    $self->{log} = $log;

    $self->log->debug("$alias: entering initialize()");

    $kernel->state('info',  $self);
    $kernel->state('warn',  $self);
    $kernel->state('error', $self);
    $kernel->state('fatal', $self);
    $kernel->state('debug', $self);

    $self->log->debug("$alias: leaving initialize()");

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Daemon::Logger - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::System;
 use XAS::Lib::Daemon::Logger

 my $log = XAS::System->module(
     logger => {
         -debug => $debug,
         -logfile => $logfile
    }
 );

 my $logger = XAS::Lib::Daemon::Logger->new(
     -alias  => 'logger',
     -logger => $log,
 );

=head1 DESCRIPTION

This module allows for multiple, asynchronous POE sessions to write to a 
common log file. It uses a predefined logger to write the log entries. This
logger should have the following methods: debug, info, warn, error, fatal.

=head1 METHODS

=head2 new

This method initializes the module and takes two parameters.

=over 4

=item B<-alias>

The alias for this session.

=item B<-logger>

The configured logging object.

=back

=head1 PUBLIC EVENTS

This module supports the following events: debug, info, warn, error, fatal.
To generate those events, someplace in your modules you would have this:

    $poe_kernel->post($logger, $level, $message);

Where $logger would be the session name of the logger, $level would be one
of the events and $message would the the entry to write to the log file.

=head2 debug

When triggered this event will call the "debug" method of the defined logger.
Passing that method the supplied log entry.

=head2 info

When triggered this event will call the "info" method of the defined logger.
Passing that method the supplied log entry.

=head2 warn

When triggered this event will call the "warn" method of the defined logger.
Passing that method the supplied log entry.

=head2 error

When triggered this event will call the "error" method of the defined logger.
Passing that method the supplied log entry.

=head2 fatal

When triggered this event will call the "fatal" method of the defined logger.
Passing that method the supplied log entry.

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
