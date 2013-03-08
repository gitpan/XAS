package XAS::Lib::Gearman::Client::Status;

our $VERSION = '0.02';

use Gearman::XS ':constants';
use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'known status numerator denominator',
  messages => {
      gearman => '%s'
  },
  vars => {
      PARAMS => {
          -handle => 1,
          -jobid  => 1,
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
    my ($ret, $known, $status, $numerator, $denominator) =
      $self->handle->job_status($self->jobid);

    if ($ret != GEARMAN_SUCCESS) {

        $self->throw_msg(
            'xas.lib.gearman.client.status',
            'gearman',
            $self->handle->error
        );

    }

    $self->{known}       = $known;
    $self->{status}      = $status;
    $self->{numerator}   = $numerator;
    $self->{denominator} = $denominator;

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Client::Status - Return the clients status.

=head1 SYNOPSIS

 use XAS:::Lib::Gearman::Client::Status;

 my $status = XAS::Lib::Gearman::Client::Status->new(
     -jobid  => $jobid,
     -handle => $handle
 );

=head1 DESCRIPTION

This module is a wrapper around the Gearman Admin protocol. If returns
an object for the status information returned by the gearman job_status call.

=head1 METHODS

=head2 new

The initializes the module and retireves the status of the job. It takes
two parameters:

=over 4

=item B<-jobid>

The id of the background job.

=item B<-handle>

The handle to the gearman interface.

=back

=head2 known

Returns wither the job is known to gearman.

=head2 status

Returns the status of the job.

=head2 numerator

Returns the numerator of the status.

=head2 denominator

Returns the denominator of the status.

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

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
