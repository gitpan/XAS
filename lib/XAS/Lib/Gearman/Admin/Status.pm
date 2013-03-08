package XAS::Lib::Gearman::Admin::Status;

our $VERSION = '0.02';

use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim',
  accessors => 'queue total running available',
  messages => {
      invline => 'invalid line format',
  },
  vars => {
      PARAMS => {
          -line => 1,
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

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $line = trim($self->line);

    if ($line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)$/) {

        $self->{queue}     = $1;
        $self->{total}     = $2;
        $self->{running}   = $3;
        $self->{available} = $4;

    } else {

        $self->throw_msg(
            'xas.lib.gearman.admin.status.invline',
            'invline'
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Admin::Status - An interface to the Gearman job queue.

=head1 SYNOPSIS

 use XAS:::Lib::Gearman::Admin::Status;

 my $status = XAS::Lib::Gearman::Admin::Status->new(
     -line => $line
 );

=head1 DESCRIPTION

This module is a wrapper around the Gearman Admin protocol. If unifies common
methods with error handling to make main line code easier to work with.

=head1 ACCESSORS

=head2 queue 

Returns the queue.

=head2 total 

Returns the total number of workers.

=head2 running 

Returns the number that are running.

=head2 available

Returns the number that are available.

=head1 SEE ALSO

 Gearman::XS
 Gearman::XS::Client

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
