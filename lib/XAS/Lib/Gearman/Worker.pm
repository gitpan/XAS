package XAS::Lib::Gearman::Worker;

our $VERSION = '0.02';

use Params::Validate ':all';
use Gearman::XS ':constants';

use XAS::Class
  version  => $VERSION,
  base     => 'XAS::Lib::Gearman',
  codec    => 'JSON',
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

sub work {
    my ($self) = shift;

    my $ret = $self->handle->work();
    if (($ret != GEARMAN_SUCCESS) && ($ret != GEARMAN_UNEXPECTED_PACKET)) {

        $self->throw_msg(
            'xas.lib.gearman.worker.work',
            'gearman',
            $self->handle->error
        );

    }

}

sub add_function {
    my $self = shift;

    my %p = validate(@_,
        {
            -queue    => 1,
            -function => {type => CODEREF},
            -options  => 1
        }
    );

    my $ret = $self->handle->add_function(
        $p{'-queue'},
        0,
        $p{'-function'},
        $p{'-options'}
    );
    if ($ret != GEARMAN_SUCCESS) {

        $self->throw_msg(
            'xas.lib.gearman.worker.add_function',
            'gearman',
            $self->handle->error
        );

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($class, $config) = @_;

    $config->{'-module'} = 'Gearman::XS::Worker';
    my $self = $class->SUPER::init($config);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Worker - An interface to the Gearman job queue.

=head1 SYNOPSIS

 use XAS::Lib::Gearman::Worker;

 sub reverse {
    my $job = shift;

    ....
    ....

 }

 my $worker = XAS::Lib::Gearman::Worker->new(
     -server => 'localhost',
     -port   => '4730'
 );

 $worker->add_function(
     -queue    => 'reverse',
     -function => \&reverse,
     -options  => {}
 );
 
 while ($worker->work());

=head1 DESCRIPTION

This is a wrapper module around Gearman::XS::Worker.

=head1 METHODS

=head2 new

This method intializes the module and connects to the gearman server. It
takes two parameters:

=over 4

=item B<-server>

The server where gearman resides, defaults to 'localhost'.

=item B<-port>

The IP port that gearman is listening on, defaults to 4730.

=back

=head2 work

This method is used to wait for work from gearman. It handles some common
error conditions. It will throw an exception when something unexpected 
happens.

=head2 add_function

Notify gearman that we can handle this function. It takes three parameters:

=over 4

=item B<-queue>

The queue that this procedure will listen on.

=item B<-function>

The callback that will do the work.

=item B<-options>

Options to be passed to gearman.

=back

=head1 SEE ALSO

 Gearman::XS
 Gearman::XS::Client
 Gearman::XS::Worker

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
