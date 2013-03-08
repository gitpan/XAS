package XAS::Lib::Net::Client;

our $VERSION = '0.02';

use IO::Socket;
use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim',
  accessors => 'handle',
  mutators  => 'timeout',
  messages => {
      connection => "unable to connect to %s on port %s",
      network    => "a network communication error has occured, reason: %s",
      noport     => "no -port was defined",
      nohost     => "no -host was defined",
  },
  vars => {
      PARAMS => {
          -port    => 1,
          -host    => 1,
          -timeout => { optional => 1, default => 60 },
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
# Public Methods
# ----------------------------------------------------------------------

sub connect {
    my ($self) = @_;

    $self->{handle} = IO::Socket::INET->new(
        Proto    => 'tcp',
        PeerPort => $self->config('-port'),
        PeerAddr => $self->config('-host'),
    ) or $self->throw_msg(
        'xas.lib.net.client.connect.noconnect',
        'connection', 
        $self->config('-host'), 
        $self->config('-port')
    );

}

sub disconnect {
    my ($self) = @_;

    if ($self->handle->connected) {

        $self->handle->close();

    }

}

sub get {
    my ($self) = @_;

    my $packet;
    my $timeout = $self->handle->timeout;

    $self->handle->timeout($self->timeout) if ($self->timeout);

    # temporarily set the INPUT_RECORD_SEPERATOR

    local $/ = "\012\015";

    $self->handle->clearerr;
    $packet = $self->handle->getline();
    chomp($packet);

    $self->throw_msg(
        'xas.lib.net.client.get', 
        'network',
        $!
    ) if ($self->handle->error);

    $self->handle->timeout($timeout);

    return $packet;

}

sub put {
    my ($self, $packet) = @_;

    my $timeout = $self->handle->timeout;

    $self->handle->timeout($self->timeout) if ($self->timeout);
    $self->handle->clearerr;
    $self->handle->printf("%s\012\015", trim($packet));

    $self->throw_msg(
        'xas.lib.net.client.put', 
        'network',
        $!
    ) if ($self->handle->error);

    $self->handle->timeout($timeout);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Net::Client - The network client interface for the XAS environment

=head1 SYNOPSIS

 my $rpc = XAS::Lib::Net::Client->new(
   -port => 9505,
   -host => 'localhost',
 };

=head1 DESCRIPTION

This module implements a simple text orientated nework protocol. All "packets" 
will have an explict "\012\015" appended. This delineates the "packets" and is
network netural. No attempt is made to decipher these "packets". 

=head1 METHODS

=head2 new

This initilaizes the module and can take three parameters. It doesn't actually
make a network connection.

=over 4

=item B<-port>

The port number to attach too.

=item B<-host>

The host to use for the connection. This can be an IP address or
a hostname.

=item B<-timeout>

An optional timeout, it defaults to 60 seconds.

=back

=head2 connect

Connect to the defined socket.

=head2 disconnect

Disconnect from the defined socket.

=head2 put($packet)

This writes a "packet" to the socket. 

=over 4

=item B<$packet>

The "packet" to send over the socket. 

=back

=head2 get

This reads a "packet" from the socket. 

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
