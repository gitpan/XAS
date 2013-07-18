package XAS::Docs::Base;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Base - the documentation for the XAS enviroments modules

=head1 MODULES

The following are the modules provided with the system. 

=head2 Basic Interface

=over 4

=item L<XAS::Base|XAS::Base>

=item L<XAS::Class|XAS::Class>

=item L<XAS::Constants|XAS::Constants>

=item L<XAS::Exception|XAS::Exception>

=item L<XAS::System|XAS::System>

=item L<XAS::Utils|XAS::Utils>

=back

=head2 Provided Applications

=over 4

=item L<XAS::Apps::Base::Alerts|XAS::Apps::Base::Alerts>

=item L<XAS::Apps::Base::Collector|XAS::Apps::Base::Collector>

=item L<XAS::Apps::Base::ExtractData|XAS::Apps::Base::ExtractData>

=item L<XAS::Apps::Base::ExtractGlobals|XAS::Apps::Base::ExtractGlobals>

=item L<XAS::Apps::Base::RemoveData|XAS::Apps::Base::RemoveData>

=item L<XAS::Apps::Database::Schema|XAS::Apps::Database::Schema>

=back

=head2 Provided Templates

=over 4

=item L<XAS::Apps::Templates::Daemon|XAS::Apps::Templates::Daemon>

=item L<XAS::Apps::Templates::Generic|XAS::Apps::Templates::Generic>

=back

=head2 Provided Examples

=over 4

=item L<XAS::Apps::Test::Echo::Client|XAS::Apps::Test::Echo::Client>

=item L<XAS::Apps::Test::Echo::Server|XAS::Apps::Test::Echo::Server>

=item L<XAS::Apps::Test::RPC::Client|XAS::Apps::Test::RPC::Client>

=item L<XAS::Apps::Test::RPC::Methods|XAS::Apps::Test::RPC::Methods>

=item L<XAS::Apps::Test::RPC::Server|XAS::Apps::Test::RPC::Server>

=back

=head2 The Collector Interface

=over 4

=item L<XAS::Collector::Alert|XAS::Collector::Alert>

=item L<XAS::Collector::Base|XAS::Collector::Base>

=item L<XAS::Collector::Connector|XAS::Collector::Connector>

=item L<XAS::Collector::Factory|XAS::Collector::Factory>

=back

=head2 General Purpose Routines

=over 4

=item L<XAS::Lib::App|XAS::Lib::App>

=item L<XAS::Lib::App::Daemon|XAS::Lib::App::Daemon>

=item L<XAS::Lib::App::Daemon::POE|XAS::Lib::App::Daemon::POE>

=item L<XAS::Lib::Connector|XAS::Lib::Connector>

=item L<XAS::Lib::Counter|XAS::Lib::Counter>

=item L<XAS::Lib::Daemon::Logger|XAS::Lib::Daemon::Logger>

=item L<XAS::Lib::Daemon::Logging|XAS::Lib::Daemon::Logging>

=item L<XAS::Lib::Gearman|XAS::Lib::Gearman>

=item L<XAS::Lib::Gearman::Admin|XAS::Lib::Gearman::Admin>

=item L<XAS::Lib::Gearman::Admin::Status|XAS::Lib::Gearman::Admin::Status>

=item L<XAS::Lib::Gearman::Admin::Worker|XAS::Lib::Gearman::Admin::Worker>

=item L<XAS::Lib::Gearman::Client|XAS::Lib::Gearman::Client>

=item L<XAS::Lib::Gearman::Client::Status|XAS::Lib::Gearman::Client::Status>

=item L<XAS::Lib::Gearman::Worker|XAS::Lib::Gearman::Worker>

=item L<XAS::Lib::Net::Client|XAS::Lib::Net::Client>

=item L<XAS::Lib::Net::Server|XAS::Lib::Net::Server>

=item L<XAS::Lib::RPC::JSON::Client|XAS::Lib::RPC::JSON::Client>

=item L<XAS::Lib::RPC::JSON::Server|XAS::Lib::RPC::JSON::Server>

=item L<XAS::Lib::Session|XAS::Lib::Session>

=item L<XAS::Lib::Spool|XAS::Lib::Spool>

=item L<XAS::Lib::Stomp::Frame|XAS::Lib::Stomp::Frame>

=item L<XAS::Lib::Stomp::Parser|XAS::Lib::Stomp::Parser>

=item L<XAS::Lib::Stomp::Utils|XAS::Lib::Stomp::Utils>

=item L<XAS::Lib::Stomp::POE::Client|XAS::Lib::Stomp::POE::Client>

=item L<XAS::Lib::Stomp::POE::Filter|XAS::Lib::Stomp::POE::Filter>

=back

=head2 The Database Interface

=over 4

=item L<XAS::Model::Database|XAS::Model::Database>

=item L<XAS::Model::Database::Alert|XAS::Model::Database::Alert>

=item L<XAS::Model::Database::Counter|XAS::Model::Database::Counter>

=item L<XAS::Model::DBM|XAS::Model::DBM>

=back

=head2 The Monitor Interface

=over 4

=item L<XAS::Monitor::Base|XAS::Monitor::Base>

=item L<XAS::Monitor::Database|XAS::Monitor::Database>

=item L<XAS::Monitor::Database::Alert|XAS::Monitor::Database::Alert>

=back

=head2 The Scheduler Interface

=over 4

=item L<XAS::Scheduler::Base|XAS::Scheduler::Base>

=back

=head2 Basic System Routines

=over 4

=item L<XAS::System::Alert|XAS::System::Alert>

=item L<XAS::System::Email|XAS::System::Email>

=item L<XAS::System::Environment|XAS::System::Environment>

=item L<XAS::System::Logger|XAS::System::Logger>

=back

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
