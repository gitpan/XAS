package XAS::Spooler::Connector;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Connector',
  constants => 'TRUE FALSE ARRAY',
  codec     => 'JSON',
  messages => {
      nohostname  => "no Hostname was defined",
      noprocessor => "no Processor was defined",
      noqueue     => "no Queue was defined",
  },
  vars => {
    PARAMS => {
        -processor => 1,
        -queues    => 1,
        -hostname  => 1,
        
    }
  }
;

use Data::Dumper;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_receipt {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $count = 0;
    my $alias = $self->alias;
    my ($palias, $filename) = split(';', $frame->header->receipt_id);

    $self->log('debug', "$alias: alias = $palias, receipt = $filename");

    $kernel->post($palias, 'unlink_file', $filename);

}

sub connection_down {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $alias = $self->alias;
    my $processor = $self->processor;

    $self->log('debug', "$alias: entering connection_down()");

    $processor->stop_scan();

    $self->log('debug', "$alias: leaving connection_down()");

}

sub connection_up {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $alias = $self->alias;
    my $processor = $self->processor;

    $self->log('debug', "$alias: entering connection_up()");

    $processor->start_scan();

    $self->log('debug', "$alias: leaving connection_up()");

}

sub handle_shutdown {
    my ($self, $kernel) = @_;

    my $alias = $self->alias;
    my $processor = $self->processor;

    $self->log('debug', "$alias: entering handle_shutdown()");

    $processor->shutdown();

    $self->log('debug', "$alias: leaving handle_shutdown()");

}

sub gather_data {
    my ($kernel, $self, $palias, $type, $packet, $file) = @_[KERNEL,OBJECT,ARG0...ARG3];

    my $alias = $self->alias;

    $self->log('debug', "$alias: entering gather_data()");

    $self->send_packet($kernel, $palias, $type, $packet, $file);

    $self->log('debug', "$alias: leaving gather_data()");

}

sub send_packet {
    my ($self, $kernel, $palias, $type, $packet, $file) = @_;

    my $data;
    my $queue;
    my $frame;
    my $message;
    my $alias = $self->alias;
    my $queues = $self->queues;

    $message->{hostname} = $self->hostname;
    $message->{timestamp} = time();
    $message->{type} = $type;
    $message->{data} = $packet;
    $data = encode($message);

    if (ref($queues) eq ARRAY) {

        $queue = $self->_get_queue($type, $queues);

    } else {

        $queue = $queues;

    }

    $frame = $self->stomp->send(
        -destination => $queue, 
        -message     => $data, 
        -receipt     => sprintf("%s;%s", $palias, $file),
        -persistent  => 'true'
    );

    $self->log('info', "$alias: sending $file to $queue");

    $kernel->call($alias, 'send_data', $frame);

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub _get_queue {
    my ($self, $type, $queues) = @_;

    foreach my $queue (@$queues) {

        return $queue->{queue} if ($queue->{type} eq $type);

    }

}

1;

__END__

=head1 NAME

XAS::Spooler::Connector - Perl extension for the XAS environment

=head1 SYNOPSIS

  use XAS::Spooler::Connector;

  my $connection = XAS::Spooler::Connector->new(
      -host             => $hostname,
      -port             => $port,
      -retry_reconnect  => TRUE,
      -enable_keepAlive => TRUE,
      -hostname         => $xas->host,
      -alias            => 'connector',
      -processor        => $processor,
      -logger           => 'logger',
      -queue            => $ddc_queue
  );

=head1 DESCRIPTION

This module use to connect to a message queue server for spoolers. It provides
the necessary events and methods so the Factory can do its job.

=head1 PUBLIC METHODS

=head2 new

This method creates the initial session, setups the scheduling for 
gather_data() and initializes JSON processing. It takes the following
configuration items:

=over

=item B<-processor>

A pointer to the ProcessFactory object.

=item B<-queue>

The name of the queue to send messages to on the message queue server.

=item B<-hostname>

The name of the host that this is running on.

=back

=head1 PUBLIC EVENTS

=head2 connection_down

This event signal that the connection had been dropped, we are just stopping 
the collection of data. This is done by notifing the ProcessFactory that
data collection should stop.

=head2 handle_shutdown

This event notifies the ProcessFactory that we are shutting down.

=head2 gather_data

This event provides an interface to the ProcesFactory to send data to the
message queue server.

=head2 send_packet

This event will format the data to be sent to the message queue server.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
