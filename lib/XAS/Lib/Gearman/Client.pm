package XAS::Lib::Gearman::Client;

our $VERSION = '0.02';

use Params::Validate ':all';
use Gearman::XS ':constants';
use XAS::Lib::Gearman::Client::Status;

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::Gearman',
  codec   => 'JSON',
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

sub process {
    my $self = shift;

    my %p = validate(@_,
        {
            -queue    => {type => SCALAR},
            -params   => {type => HASHREF},
            -status   => {type => CODEREF, optional => 1},
            -priority => { optional => 1, default => 'medium', regex => qr/low|medium|high/ },
        }
    );

    my $ret;
    my $task;
    my $data;
    my $queue = $p{'-queue'};
    my $status = $p{'-status'};
    my $priority = $p{'-priority'};
    my $params = encode($p{'-params'});

    $self->handle->set_complete_fn(sub {
        my $task = shift;
        $data = $task->data;
        return GEARMAN_SUCCESS;
    });

    $self->handle->set_status_fn(sub {
        my $task = shift;
        if (defined($status)) {
            $status->(
                -jobid       => $task->job_handle,
                -numerator   => $task->numerator,
                -denominator => $task->denominator
            );
        }
        return GEARMAN_SUCCESS;
    });

    $self->handle->set_warning_fn(sub {
        my $task = shift;
        my ($type, $info) = ($task->data =~ m/(.*):(.*)/);
        $self->handle->clear_fn();
        $self->throw_msg(
            $type,
            'gearman',
            $info
        );
        return GEARMAN_SUCCESS;
    });

    if ($priority eq 'low') {

        ($ret, $task) = $self->handle->add_task_low($queue, $params);

    } elsif ($priority eq 'high') {

        ($ret, $task) = $self->handle->add_task_high($queue, $params);

    } else {

        ($ret, $task) = $self->handle->add_task($queue, $params);

    }

    if ($ret != GEARMAN_SUCCESS) {

        $self->handle->clear_fn();
        $self->throw_msg(
            'xas.lib.gearman.client.process',
            'gearman',
            $self->handle->error
        );

    }

    $ret = $self->handle->run_tasks();
    if ($ret != GEARMAN_SUCCESS) {

        $self->handle->clear_fn();
        $self->throw_msg(
            'xas.lib.gearman.client.process',
            'gearman',
            $self->handle->error
        );

    }

    $self->handle->clear_fn();

    return $data;

}

sub submit {
    my $self = shift;

    my %p = validate(@_,
        {
            -queue    => {type => SCALAR},
            -params   => {type => HASHREF},
            -priority => { optional => 1, default => 'medium', regex => qr/low|medium|high/ },
        }
    );

    my $ret;
    my $jobid;
    my $queue = $p{'-queue'};
    my $priority = $p{'-priotity'};
    my $params = encode($p{'-params'});

    if ($priority eq 'low') {

        ($ret, $jobid) = $self->handle->do_low_background($queue, $params);

    } elsif ($priority eq 'high') {

        ($ret, $jobid) = $self->handle->do_high_background($queue, $params);

    } else {

        ($ret, $jobid) = $self->handle->do_background($queue, $params);

    }

    if ($ret != GEARMAN_SUCCESS) {

        $self->throw_msg(
            'xas.lib.gearman.client.submit',
            'gearman',
            $self->handle->error
        );

    }

    return $jobid;

}

sub status {
    my $self = shift;

    my %p = validate(@_,
        {
            -jobid => {type => SCALAR}
        }
    );

    return XAS::Lib::Gearman::Client::Status->new(
        -jobid  => $p{'-jobid'},
        -handle => $self->handle
    );

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($class, $config) = @_;

    $config->{'-module'} = 'Gearman::XS::Client';
    my $self = $class->SUPER::init($config);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Client - An interface to the Gearman job queue.

=head1 SYNOPSIS

 use XAS:::Lib::Gearman::Client;

 my $client = XAS::Lib::Gearman::Client->new(
     -server => 'localhost',
     -port   => '4730'
 );

 my $data = $client->process('reverse', {string => 'this is a string'});
 printf("reversed: %s\n", $data);

=head1 DESCRIPTION

This module is a wrapper around the Gearman::XS::Client. If unifies common
methods with error handling to make main line code easier to work with.

=head1 METHODS

=head2 process

This method runs a task in the foreground. It returns the processed
response from the worker. It takes the following parameters:

=over 4

=item B<-queue>

The queue to run the task under.

=item B<-params>

The paramters for that task. They should be a hashref.

=item B<-status>

An optional call back to report the status of the running task. The callback
will take these following parameters:

=over 4

=item B<-jobid>

The ID of the job.

=item B<-numerator>

The numerator of the status.

=item B<-denominator>

The denominator of the status.

=back

=item B<-priority>

An optional priority to run the job at. The priorities are 'low', 'medium' 
and 'high'. The default is 'medium'.

=back

=head2 submit

This method will submit a job to be run in the background. It will return the 
job id of the background task. It takes the following parameters:

=over 4

=item B<-queue>

The queue to run the task on.

=item B<-params>

The paramters to pass to the job. This should be a hashref.

=item B<-priority>

An optional priority to run the job at. The priorities are 'low', 'medium' 
and 'high'. The default is 'medium'.

=back

=head2 status

This method will return the status of a background job. It returns a 
L<XAS::Lib::Gearman::Client::Status|XAS::Lib::Gearman::Client::Status>  object.
It takes following parameter:

=over 4

=item B<-jobid>

The id of the background job.

=back

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
