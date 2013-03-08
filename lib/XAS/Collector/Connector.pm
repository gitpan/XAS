package XAS::Collector::Connector;

our $VERSION = '0.01';

use POE;
use Try::Tiny;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Connector',
  constants => 'TRUE FALSE ARRAY',
  codec     => 'JSON',
  messages => {
      unknownmsg => "%s: unknown protocol type: %s",
      noqueues   => "no Queues were defined",
      notypes    => "no Types were defined",
  }
;

use Data::Dumper;

# ---------------------------------------------------------------------
# Public Events
# ---------------------------------------------------------------------

sub handle_connected {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $nframe;
    my $alias = $self->config('Alias');
    my $queues = $self->config('Queues');

    if (ref($queues) eq ARRAY) {

        for my $q (@$queues) {

            $nframe = $self->stomp->subscribe(
                {
                    destination => $q,
                    ack         => 'client'
                }
            );

            $self->log($kernel, 'info', $self->message('subscribed', $alias, $q));
            $kernel->yield('send_data', $nframe);

        }

    } else {

        $nframe = $self->stomp->subscribe(
            {
                destination => $queues,
                ack         => 'client'
            }
        );

        $self->log($kernel, 'info', $self->message('subscribed', $alias, $queues));
        $kernel->yield('send_data', $nframe);

    }

}

sub handle_message {
    my ($kernel, $self, $frame) = @_[KERNEL, OBJECT, ARG0];

    my $data;
    my $message;
    my $session;
    my $alias = $self->config('Alias');
    my $types = $self->config('Types');
    my $message_id = $frame->headers->{'message-id'};
    my $nframe = $self->stomp->ack({'message-id' => $message_id});

    try {

        $message = decode($frame->body);

        $self->log($kernel, 'info', 
            $self->message(
                'received', 
                $alias, 
                $message_id, 
                $message->{type}, 
                $message->{hostname}
            )
        );

        $data = $message->{data};
        $session = $self->_get_session($message->{type}, $types);

        if (defined($session)) {

            $kernel->call($session, 'store_data', $data, $nframe);

        } else {

            $self->throw_msg(
                'xas.collector.connector.handle_message',
                'unknownmsg',
                $alias, $message->{type}
            );

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub spawn {
    my $class = shift;

    my %args = @_;
    my $self = $class->SUPER::spawn(@_);

    unless (defined($args{'Types'})) {

        $self->throw_msg(
            'xas.collector.connector.spawn.notypes',
            'notypes'
        );

    }

    unless (defined($args{'Queues'})) {

        $self->throw_msg(
            'xas.collector.connector.spawn.noqueues',
            'noqueues'
        );

    }

    return $self;

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub _get_session {
    my ($self, $wanted, $types) = @_;

    my $key;
    my $type;
    my $session;

    for $type ( @$types ) {
        for $key ( keys %$type ) {
            $session = $type->{$key} if ($key eq $wanted);
        }
    }

    return $session;

}
1;

__END__

=head1 NAME

XAS::Collector::Connector - Perl extension for the XAS environment

=head1 SYNOPSIS

  use XAS::Collector::Connector;

  my $types = [
     { 'xas-alert', 'alert' },
  ];

  my $queues = [
      '/queue/alert',
  ];

  XAS::Collector::Connector->spawn(
      RemoteAddress => $host,
      RemotePort    => $port,
      Alias         => 'collector',
      Logger        => 'logger',
      Login         => 'collector',
      Passcode      => 'ddc',
      Queues        => $queues,
      Types         => $types
  );

=head1 DESCRIPTION

This module is used for monitoring queues on the message server. When messages
are received, they are then passed off to the appropriate message handler.

=head1 METHODS

=head2 spawn

The module uses the configuration items from POE::Component::Client::Stomp
along with this additional items.

=over 4 

=item B<Queues>

The queues that the connector will subscribe too. This can be a string or
an array of strings.

=item B<Types>

This is a list of XAS packet types that this connector can handle. The list
consists of hashes with the following values: XAS packet type, name of 
the session handler for that packet type.

=back

=head1 PUBLIC EVENTS

=head2 handle_connected($kernel, $self, $frame)

Subscribe to the appropriate queue(s) after authentication.

=over 4

=item B<$kernel>

A handle to the POE kernel

=item B<$self>

A handle to the current object.

=item B<$frame>

The received STOMP frame.

=back

=head2 handle_message($kernel, $self, $frame)

Decode the packet type and pass it off to the appropriate message handler.

=over 4

=item B<$kernel>

A handle to the POE kernel

=item B<$self>

A handle to the current object.

=item B<$frame>

The received STOMP frame.

=back

=head1 SEE ALSO

 POE::Component::Client::Stomp

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
