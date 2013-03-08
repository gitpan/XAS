package XAS::Collector::Factory;

our $VERSION = '0.02';

use Config::IniFiles;
use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base Badger::Prototype',
  utils     => 'load_module',
  accessors => 'collectors',
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
# Public Methods
# ----------------------------------------------------------------------

sub load {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    my %p = validate(@_,
        {
            -connector => 1,
            -logger    => 1,
            -configs   => 1,
        }
    );

    my $cfg;
    my @sections;
    my @collectors;
    my $filename = $p{'-configs'}->path;

    if ($cfg = Config::IniFiles->new(-file => $filename)) {

        @sections = $cfg->Sections;

        foreach my $section (@sections) {

            next if ($section !~ /^collector:/);

            my $module = $cfg->val($section, 'module');

            load_module($module);

            my $collector = $module->new(
                -alias     => $cfg->val($section, 'alias'),
                -connector => $p{'-connector'},
                -logger    => $p{'-logger'},
            );

            push(@collectors, $collector);

        }

    } else {

        $self->throw_msg(
            'xas.colletor.factory.load.badini', 
            'badini', 
            $p{'-configs'}
        );

    }

    $self->{collectors} = \@collectors;

    return $self;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Collector::Factory - A factory method to load collector processors

=head1 SYNOPSIS

This module is used to create multiple collectors from a configuration file.

 my $collectors = XAS::Collector::Factory->load(
    -connector => 'connector',
    -logger    => 'logger',
    -configs   => 'collectors.ini'
 );

=head1 DESCRIPTION

This module will take a configuration file and starts all the collectors 
defined within. 

=head2 Configuration File

The configuraton file has the following cavets:

=over 4

=item o Item names are case sensitve.

=item o A ";" indicates the start of a comment.

=item  o The section header must be unique and start with "collector:".

=back

The file format follows the familiar Win32 .ini format. 

  ; My configuration file
  ;
  [collector: alert]
  alias = alert
  queue = /queue/alert
  packet-type = xas-alert
  module = XAS::Collector::Alert

=head2 Configuration Items

=over 4

=item B<alias>

The alias for the POE Session.

=item  B<packet-type>

The XAS packet type. Defaults to 'unknown'.

=item B<module>

The module to load to handle this packet type.

=item B<queue>

The queue to listen on for packets.

=back

=head1 METHODS

=head2 load

This loads the configuration file and starts the collectors.

=head1 ACCESSORS

=head2 collectors

Returns a list of collectors.

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
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
