package XAS::Monitor::Database;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use Params::Validate;
use POE::Component::Cron;

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Monitor::Base',
  accessors  => 'cron schema',
  constants  => 'TRUE FALSE',
  messages => {
      remote   => "Remote file doesn't exist: %s",
      noaccess => "No access to remote system: %s",
  },
  vars => {
      PARAMS => {
          -schedule => { optional => 1, default => '*/1 * * * *' },
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
# Public Events
# ----------------------------------------------------------------------

sub startup {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $alias = $self->alias;
    my $crontab = $self->schedule;

    $self->log('debug', "$alias: entering startup()");

    $self->{cron} = POE::Component::Cron->from_cron($crontab, $alias, 'monitor');
    $kernel->yield('monitor');

    $self->log('debug', "$alias: leaving startup()");

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub initialize {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;

    $self->log('debug', "$alias: entering initialize()");

    $kernel->state('monitor', $self);

    try {

        $self->{schema} = XAS::Model::Database->opendb('database');

    } catch {

        my $ex = $_;

        my $buffer = $self->message('nodbaccess', 'XAS::Model::Database', $ex);
        $self->log('fatal', $buffer);
        $kernel->yield('shutdown');

    };

    $self->log('debug', "$alias: leaving initialize()");

}

sub cleanup {
    my ($self, $kernel, $session) = @_;

    if (my $cron = $self->cron) {

        $cron->delete();

    }

    $self->schema->storage->disconnect;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Monitor::Database - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Monitor::Database

 my $monitor = XAS::Monitor::Database->new(
     -alias     => 'monitor',
     -logger    => 'logger',
     -schedule  => '*/1 * * * *',
 );
 
=head1 DESCRIPTION

This module inherits from XAS::Monitor::Base and provides a base class for
monitors that monitor items within a databae.

=head1 METHODS

=head2 new

This method initializes the module and take these three parameters:

=over 4

=item B<-alias>

The name of this session.

=item B<-logger>

The alias for the logger session.

=item B<-schedule>

The schedule to follow when monitoring. It defaults to: "*/1 * * * *". 
Which is do something once a minute.

=back

=head2 initialize

This method declares the event "monitor" and opens the connection to the 
database.

=head2 cleanup

This method stops the "monitor" processing and closes the database connection.

=head2 monitor

The method that does the actual monitoring. By default it does nothing and 
needs to be overridden. The overridden method takes two parameters: 

=over 4

=item B<$kernel>

A handle to the POE kernel.

=item B<$self>

A reference to it's self.

=back

=head1 PUBLIC EVENTS

=head2 startup

This event schedules the processing of "monitor" with the supplied schedule.

=head2 shutdown

This is triggered by a "shutdown" event and calls the cleanup() method.

=head2 monitor

This is triggered by the schedule and calls the monitor() method.

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
