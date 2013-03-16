package XAS::Collector::Alert;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use XAS::Model::Database 'Alert';

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Collector::Base',
;

use Data::Dumper;

# --------------------------------------------------------------------
# Public Events
# --------------------------------------------------------------------

sub store_data {
    my ($kernel, $self, $data, $ack) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $msg;
    my $buffer;
    my $alias = $self->alias;
    my $schema = $self->schema;
    my $connector = $self->connector;

    $self->log('debug', "$alias: entering store_data()");

    $buffer = sprintf("%s: hostname = %s; timestamp = %s; priority = %s; facility = %s; message = %s",
        $alias, $data->{hostname}, $data->{datetime}, $data->{priority}, 
        $data->{facility}, $data->{message}
    );

    $self->log('debug', $buffer);

    try {

        $schema->txn_do(sub {

            $data->{revision} = 1;
            Alert->create($schema, $data);

        });

        $self->log('info', $self->message('processed', $alias, 1, $data->{hostname}, $data->{datetime}));

    } catch {

        my $ex = $_;

        my $key = {
            HostName => $data->{hostname},
            DateTime => $data->{datetime},
        };

        $self->exception_handler($ex, $key, $data);

    };

    $kernel->call($connector, 'send_data', $ack);

    $self->log('debug', "$alias: leaving store_notify()");

}

# --------------------------------------------------------------------
# Public Methods
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# Private Methods
# --------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Collector::Alert - Perl extension for the XAS Environment

=head1 SYNOPSIS

  use XAS::Collector::Alert;
  use XAS::Collector::Connector;

  main: {

      my $types = [
          {'xas-alert', 'alert'}
      ];

      XAS::Collector::Connector->spawn(
          RemoteAddress   => $host,
          RemotePort      => $port,
          EnableKeepAlive => 1,
          Alias           => 'collector',
          Logger          => 'logger',
          Login           => 'xas',
          Passcode        => 'xas',
          Queue           => '/queue/alerts',
          Types           => $types
      );

      my $notify = XAS::Collector::Alert->new(
          -alias     => 'alert',
          -logger    => 'logger',
          -connector => 'connector'
      );

      $poe_kernel->run();

      exit 0;

  }

=head1 DESCRIPTION

This module handles the xas-alert packet type.

=head1 PUBLIC EVENTS

=head2 store_data($kernel, $self, $data, $ack)

This event will trigger the storage of xas-alert packets into the database. 

=over 4

=item B<$kernel>

A handle to the POE environment.

=item B<$self>

A handle to the current object.

=item B<$data>

The data to be stored within the database.

=item B<$ack>

The acknowledgement to send back to the message queue server.

=back

=head1 SEE ALSO

 XAS

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
