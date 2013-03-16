package XAS::Spooler::Processor;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::System;
use POE::Component::Cron;

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Lib::Session',
  accessors  => 'spooler cron',
  filesystem => 'Dir',
  messages => {
      unlinking => '%s: unlinking %s',
      found     => '%s: found spool file %s',
  },
  vars => {
      PARAMS => {
          -connector => 1,
          -logger    => 1,
          -directory => 1,
          -packet_type => 1,
          -schedule => { optional => 1, default => '*/1 * * * *' },
      }
  }
;

# ---------------------------------------------------------------------
# Event Handlers
# ---------------------------------------------------------------------

sub startup {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    $kernel->yield('start_scan');

}

sub start_scan {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $alias = $self->alias;

    $self->log('debug', "$alias: entering start_scan()");

    $self->{cron} = POE::Component::Cron->from_cron(
        $self->schedule => $alias => 'scan'
    );

    $self->log('debug', "$alias: leaving start_scan()");

}

sub stop_scan {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $alias = $self->alias;

    $self->log('debug', "$alias: entering stop_scan()");

    if (my $cron = $self->cron) {

        $cron->delete();

    }

    $self->log('debug', "$alias: leaving stop_scan()");

}

sub scan {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $packet;
    my $alias = $self->alias;
    my $type = $self->packet_type;
    my $connector = $self->connector;

    $self->log('debug', "$alias: entering scan()");

    try {

        if (my $file = $self->spooler->get()) {

            $self->log('info', $self->message('found', $alias, $file));

            $packet = $self->spooler->read($file);
            $kernel->post($connector, 'gather_data', $alias, $type, $packet, $file);

        }

    } catch {

        my $ex = $_;
        my $ref = ref($ex);

        if ($ref && $ex->isa('XAS::Exception')) {

            my $type = $ex->type();
            my $info = $ex->info();

            $self->log('warn', "$alias: $type, $info");

        } else {

            my $type = sprintf("%s", $ex);

            $self->log('warn', $type);

        }

    };

    $self->log('debug', "$alias: leaving scan()");

}

sub unlink_file {
    my ($kernel, $self, $file) = @_[KERNEL,OBJECT,ARG0];

    my $count;
    my $alias = $self->alias;

    $self->log('debug', "$alias: entering unlink_file()");
    $self->log('info', $self->message('unlinking', $alias, $file));

    $self->spooler->delete($file);

    if (($count = $self->spooler->count()) > 1) {

        $kernel->alarm_remove_all();
        $self->log('debug', "$alias: $count items waiting, queueing scan()");
        $kernel->delay_add('scan', 5);

    }

    $self->log('debug', "$alias: leaving unlink_file()");

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub log {
    my ($self, $level, @args) = @_;

    my $logger = $self->logger;

    $poe_kernel->post($logger, $level, @args);

}

sub initialize {
    my ($self, $kernel, $session) = @_;

    my $spooldir;
    my $alias = $self->alias;

    $self->log('debug', "$alias: entering initialize()");

    try {

        $kernel->state('scan', $self);
        $kernel->state('stop_scan', $self);
        $kernel->state('start_scan', $self);
        $kernel->state('unlink_file', $self);

        $spooldir = Dir($self->env->spool, $self->directory);
        $self->{spooler} = XAS::System->module(
            spool => {
                -spooldir => $spooldir
            }
        );

    } catch {

        my $ex = $_;

        $self->log('fatal', sprintf('%s', $ex));
        $kernel->yield('shutdown');

    };

    $self->log('debug', "$alias: leaving initialize()");

}

sub cleanup {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;

    $self->log('debug', "$alias: entering cleanup()");

    $kernel->call($alias, 'stop_scan');

    $self->log('debug', "$alias: leaving cleanup()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Spooler::Processor - Perl extension for the XAS environment

=head1 SYNOPSIS

  use XAS::Spooler::Processor;

  my $processor = XAS::Spooler::Processor->new(
      -schedule    => '*/1 * * * *',
      -connector   => 'connector',
      -logger      => 'logger',
      -alias       => 'nmon',   
      -directory   => 'nmon',     
      -packet_type => 'ddc-nmon'
  );

=head1 DESCRIPTION

This module scans a spool directory. When any files are found the are 
processed and sent to the Connector.

=head1 EVENTS

This module responds to the following POE events.

=head2 startup

Fires the start_scan event.

=head2 start_scan

Schedules the scanning process.

=head2 stop_scan

Stops the scanning process.

=head2 scan

Performs the scanning process and dispatchs any packets to the Connectors 
'gather_data' event.

=head2 unlink_file

Removes the unneeded file from the directory.

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
