package XAS::Docs::Base;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Base - the documentation for the XAS enviroments modules

=head1 MODULES

The following are the modules provided with the system. 

=head2 Basic Interface

 XAS::Base
 XAS::Class
 XAS::Constants
 XAS::Exception
 XAS::System
 XAS::Utils

=head2 Provided Applications

 XAS::Apps::Base::Alerts
 XAS::Apps::Base::Collector
 XAS::Apps::Base::ExtractData
 XAS::Apps::Base::ExtractGlobals
 XAS::Apps::Base::RemoveData
 XAS::Apps::Database::Schema

=head2 Provided Templates

 XAS::Apps::Templates::Daemon
 XAS::Apps::Templates::Generic

=head2 Provided Examples

 XAS::Apps::Test::Echo::Client
 XAS::Apps::Test::Echo::Server
 XAS::Apps::Test::RPC::Client
 XAS::Apps::Test::RPC::Methods
 XAS::Apps::Test::RPC::Server

=head2 The Collector Interface

 XAS::Collector::Alert
 XAS::Collector::Base
 XAS::Collector::Connector
 XAS::Collector::Factory

=head2 General Purpose Routines

 XAS::Lib::App
 XAS::Lib::App::Daemon
 XAS::Lib::App::Daemon::POE
 XAS::Lib::Connector
 XAS::Lib::Counter
 XAS::Lib::Daemon::Logger
 XAS::Lib::Daemon::Logging
 XAS::Lib::Gearman
 XAS::Lib::Gearman::Admin
 XAS::Lib::Gearman::Admin::Status
 XAS::Lib::Gearman::Admin::Worker
 XAS::Lib::Gearman::Client
 XAS::Lib::Gearman::Client::Status
 XAS::Lib::Gearman::Worker
 XAS::Lib::Net::Client
 XAS::Lib::Net::Server
 XAS::Lib::RPC::JSON::Client
 XAS::Lib::RPC::JSON::Server
 XAS::Lib::Session
 XAS::Lib::Spool

=head2 The Database Interface

 XAS::Model::Database
 XAS::Model::Database::Alert
 XAS::Model::Database::Counter
 XAS::Model::DBM

=head2 The Monitor Interface

 XAS::Monitor::Base
 XAS::Monitor::Database
 XAS::Monitor::Database::Alert

=head2 The Scheduler Interface

 XAS::Scheduler::Base

=head2 Basic System Routines

 XAS::System::Alert
 XAS::System::Email
 XAS::System::Environment
 XAS::System::Logger

=head1 SEE ALSO

 XAS

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
