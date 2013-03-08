package XAS::Monitor::Database::Alert;

our $VERSION = '0.01';

use POE;
use DateTime;
use Try::Tiny;
use Params::Validate;
use XAS::Model::Database 'Alert';

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Monitor::Database',
  utils      => 'dt2db rtrim',
  constants  => 'TRUE FALSE',
  vars => {
      PARAMS => {
          -mailer     => 1,
          -email_to   => 1,
          -email_from => 1,
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

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub monitor {
    my ($kernel, $self) = @_[KERNEL,OBJECT];

    my $buffer;
    my $before;
    my $criteria;
    my $send_email = FALSE;
    my $alias = $self->alias;
    my $email = $self->mailer;
    my $schema = $self->schema;
    my $now = DateTime->now(time_zone => 'local');

    $self->log('debug', "$alias: entering monitor()");

    try {

        $before = $now->clone->subtract(hours => 1);
        $criteria = {
            datetime => { '<', dt2db($before) },
            priority => 'high',
            cleared  => { '!=', 't' },
        };

        if (my $rs = Alert->search($schema, $criteria)) {

            $buffer = "The following Alerts are pending\n\n";

            while (my $rec = $rs->next) {

                $send_email = TRUE;
                $self->log('info', "$alias: " . $rec->id . " is pending");

                $buffer .= sprintf("Host    : %s\nTime     : %s\nPriority: %s\nFacility: %s\n Message : %s\n", 
                    $rec->hostname,
                    dt2db($rec->datetime),
                    $rec->priority,
                    $rec->facility,
                    $rec->message
                );

                $buffer = rtrim($buffer);
                $buffer .= "\n\n";

            }

            $buffer .= "Please check and clear these Alerts.\n\nThank you";

            if ($send_email) {

                $email->send(
                    -from    => $self->email_from,
                    -to      => $self->email_to,
                    -subject => "Pending XAS Alerts",
                    -message => $buffer
                );

            }

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

    $self->log('debug', "$alias: leaving monitor()");

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Monitor::Database::Alert - A Perl extension for the XAS environment

=head1 DESCRIPTION

This module inherits from XAS::Monitor::Database and provides the "monitor"
event.

=head1 METHODS

=head2 new

This method initializes the module and accepts the following parameters along
with any others needed by XAS::Monitor::Database.

=over 4

=item B<-mailer>

The mailer to use.

=item B<-email_from>

The emails from address.

=item B<-email_to>

The emails to address.

=back

=head1 PUBLIC EVENTS

=head2 monitor

This event triggers the scanning of the Alert table looking for items that
have not been cleared after 15 minutes. When this happens, an email is sent
to the EmailTo address.

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
