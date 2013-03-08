package XAS::Collector::Alert;

our $VERSION = '0.01';

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
    my ($buffer, $record);
    my $alias = $self->alias;
    my $schema = $self->schema;
    my $connector = $self->connector;

    $self->log('debug', 'notify: entering store_data()');

    ($record->{hostname}, 
     $record->{datetime}, 
     $record->{priority}, 
     $record->{facility}, 
     $record->{message}) = split("\036", $data);

    $buffer = sprintf("hostname = %s; timestamp = %s; priority = %s; facility = %s; message = %s\n",
        $record->{hostname}, $record->{datetime}, $record->{priority}, 
        $record->{facility}, $record->{message}
    );

    $self->log('debug', $buffer);

    try {

        $schema->txn_do(sub {

            $record->{revision} = 1;
            Alert->create($schema, $record);

        });

        $self->log('info', $self->message('processed', $alias, 1, $record->{hostname}, $record->{datetime}));

    } catch {

        my $ex = $_;

        my $key = {
            HostName => $record->{hostname},
            DateTime => $record->{datetime},
        };

        $self->exception_handler($ex, $key, $record);

    };

    $kernel->call($connector, 'send_data', $ack);

    $self->log('debug', 'notify: leaving store_notify()');

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
          Queue           => '/queue/alert',
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

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
