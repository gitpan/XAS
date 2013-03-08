package XAS::Base;

use 5.8.8;

our $VERSION = '0.01';
our $EXCEPTION = 'XAS::Exception';

use XAS::Exception;
use Params::Validate ':all';

use XAS::Class
  base     => 'Badger::Base',
  version  => $VERSION,
  messages => {
      exception     => "%s: %s",
      dberror       => "a database error has occured: %s",
      invparams     => "invalid paramters passed, reason: %s",
      nospooldir    => "no spool directory defined",
      noschema      => "no database schema was defined",
      unknownos     => "unknown OS: %s",
      unexpected    => "unexpected error: %s",
      unknownerror  => "unknown error: %s",
      nodbaccess    => "unable to access database: %s; reason %s",
      undeliverable => "unable to send mail to %s; reason: %s",
      noserver      => "unable to connect to %s; reason: %s",
      nodelivery    => "unable to send message to %s; reason: %s",
      sequence      => "unable to retrive sequence number from %s",
      write_packet  => "unable to write a packet to %s",
      read_packet   => "unable to read a packet from %s",
      lock_error    => "unable to aquire a lock on %s",
      invperms      => "unable to change file permissions on %s",
      badini        => "unable to load config file: %s",
      expiredacct   => 'this accounts expiration day has passed',
      expiredpass   => 'this accounts password has expired',
      sessionend    => 'the session has expired',
      noaccess      => 'you are not able to access the system at this time',
      loginattempts => 'you have exceeded your login attempts',
  },
  vars => {
      PARAMS => {}
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

sub config {
    my ($class, $p) = @_;

    return $class->{config}->{$p};

}

sub validation_exception {
    my $param = shift;
    my $class = shift;

    my $x = index($param, $class);
    my $y = index($param, ' ', $x);
    my $method;

    if ($y > 0) {

        my $l = $y - $x;
        $method = substr($param, $x, $l);

    } else {

        $method = substr($param, $x);

    }

    chomp($method);
    $method =~ s/::/./g;
    $method = lc($method) . '.invparams';

    $class->throw_msg($method, 'invparams', $param);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $self = shift;

    my $params = $self->class->hash_vars('PARAMS');
    my %p = validate(@_, $params);

    $self->{config} = \%p;

    no strict "refs";               # to register new methods in package
    no warnings;                    # turn off warnings

    while (my ($key, $value) = each(%p)) {

        $key =~ s/^-//;
        $self->{$key} = $value;

        *$key = sub {
            my $self = shift;
            return $self->{$key};
        };

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Base - The base class for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
     version => '0.01',
     base    => 'XAS::Base'
 ;

=head1 DESCRIPTION

This module defines a base class for the XAS Environment and inerits from
Badger::Base.

=head1 METHODS

=head2 config($item)

This method will return an item from the internal class config. Which is 
usually the parameters passed to new() before any manipulation of those
parameters.

=over 4

=item B<$item>

The item you want to return,

=back

=head2 validation_exception($params, $class)

This method is used by Params::Validate to display it's failure  message.

=over 4

=item B<$params>

The parameter that caused the exception.

=item B<$class>

The class that it happened in.

=back

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
