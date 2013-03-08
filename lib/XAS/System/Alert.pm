package XAS::System::Alert;

our $VERSION = '0.02';

use DateTime;
use Try::Tiny;
use Net::Stomp;
use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  codec     => 'JSON',
  utils     => 'dt2db',
  accessors => 'hostname',
  mutators  => 'server port login passcode queue',
  vars => {
      PARAMS => {
          -port     => 1,
          -server   => 1,
          -passcode => { optional => 1, default => 'guest' },
          -login    => { optional => 1, default => 'guest' },
          -hostname => { optional => 1, default => 'localhost' },
          -queue    => { optional => 1, default => '/queue/alerts' },
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

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub send {
    my $self = shift;

    my %params = validate(@_, 
        { 
            -priority => 1, 
            -facility => 1,
            -message  => 1 
        }
    );

    my ($body, $frame, $stomp, $buffer, $message);
    my $dt = DateTime->now(time_zone => 'local');

    $buffer = sprintf("%s\036%s\036%s\036%s\036%s", 
        $self->hostname,
        dt2db($dt),
        $params{'-priority'}, 
        $params{'-facility'}, 
        $params{'-message'}
    );

    $message->{hostname} = $self->hostname;
    $message->{timestamp} = time();
    $message->{type} = 'xas-alert';
    $message->{data} = $buffer;
    $body = encode($message);

    try {

        $stomp = Net::Stomp->new(
            {
                hostname => $self->server,
                port     => $self->port
            }
        );

    } catch { 

        my $ex = $_;

        $self->throw_msg(
            'xas.system.alert.noserver',
            'noserver', 
            $self->mqserver, 
            $ex
        ); 

    };

    try {

        $stomp->connect({login => $self->login, passcode => $self->passcode});
        $stomp->send({destination => $self->queue, body => $body});
        $stomp->disconnect;

    } catch { 

        my $ex = $_;

        $self->throw_msg(
            'xas.system.alert.nodelivery',
            'nodelivery', 
            $self->queue,
            $ex
        );

    }

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub init {
    my $self = shift;
    
    my $params = $self->class->hash_vars('PARAMS');
    my %p = validate(@_, $params);
    
    $self->{config} = \%p;
    
    $self->{passcode} = $p{'-passcode'};
    $self->{login}    = $p{'-login'};
    $self->{queue}    = $p{'-queue'};
    $self->{hostname} = $p{'-hostname'};
    $self->{server}   = $p{'-server'};
    $self->{port}     = $p{'-port'};
    
    return $self;
    
}

1;

__END__

=head1 NAME

XAS::System::Alert - The alert module for the XAS environment

=head1 SYNOPSIS

Your program can use this module in the following fashion:

 use XAS::System;

 $alert = XAS::System->module(
     alert => {
         -hostname => 'localhost',
         -server   => 'mq.example.com',
         -port     => '9000',
     }
 );

 $alert->send(
     -priority => 'high',
     -facility => 'huston',
     -message  => 'There is a problem'
 );

 or ...

 use XAS::System;

 $xas = XAS::System->module('environment');
 $alert = XAS::System->module(
     alert => {
         -hostname => $xas->hostname
     }
 );

 $alert->send(
     -priority => 'high',
     -facility => 'huston',
     -message  => 'There is a problem'
 );

=head1 DESCRIPTION

This is the module for sending alerts within the XAS environment. 

=head1 METHODS

=head2 new

This method initializes the module. It is automatically called when invoked
by XAS::System->module(). It takes the following parameters:

=over 4

=item B<-server>

The default is mq.example.com. This default can changed with 
the environment variable MQSERVER. It can also be changed with the named 
parameter -server upon load or the server() method after loading.

=item B<-port>

The default is 61613. This default can be changed with the environment 
variable MQPORT. It can also be changed with the named parameter -port
upon load or the port() method after loading.

=item B<-queue>

The default is "/queue/alert". This default can be changed with the -queue
parameter upon load or the queue() method after loading.

=item B<-login>

The defaut is "alert". This default can be changed with the -login
parameter upon load or the login() method after loading.

=item B<-passcode>

The default is "xas". This default can be changed with the -passcode 
parameter upon load or the passcode() method after loading.

=item B<-hostname>

The default is "localhost". This value can be provided with the -hostname 
parameter. It is suggested that the hostname() method from 
XAS::System::Environment be used.

=back

=head2 send

This method will send an notification. It takes the following named parameters:

=over 4

=item B<-priority>

The notification level, 'high','medium','low'. Default 'low'.

=item B<-facility>

The notification facility, 'systems', 'dba', etc.  Default 'systems'.

=item B<-message>

The message text for the message

=back

=head2 hostname

This method will get the current hostname used for messages from this server.

Example

    $hostname = $notify->hostname;

=head1 MUTATORS

=head2 server

This can be used to get/set the server to be used for notifications.

Example

    $server = $alert->server;
    $alert->server('mq.example.com');

=head2 port

This can be used to get/set the port that will be used on the server.

Example

    $port = $alert->port;
    $alert->port('9000');

=head2 login

This can be used to get/set the login name to be used on the server.

Example

    $login = $alert->login;
    $alert->login('testing');

=head2 passcode

This can be used to get/set the passcode to be used on the server.

Example

    $passcode = $alert->passcode;
    $alert->passcode('testing');

=head2 queue

This can be used to get/set the queue to be used on the server.

Example

    $queue = $alert->queue;
    $alert->queue('/queue/testing');

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
