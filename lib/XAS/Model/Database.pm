package XAS::Model::Database;

our $VERSION = '0.01';

use Class::Inspector;
use Badger::Exception;
use Params::Validate ':all';

use XAS::Class
  version => $VERSION,
  base    => 'DBIx::Class::Schema::Config XAS::Base',
  import  => 'class',
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

use Data::Dumper;

# ---------------------------------------------------------------------
# Loading table definations
# ---------------------------------------------------------------------

my $path = defined($ENV{XAS_ROOT}) ? $ENV{XAS_ROOT} : '/opt';

__PACKAGE__->config_paths([("$path/etc/database", "$ENV{HOME}/.database")]);
__PACKAGE__->load_namespaces(result_namespace => '+XAS::Model::Database');
__PACKAGE__->exception_action(\&XAS::Model::Database::dbix_exceptions);

# ---------------------------------------------------------------------
# Building constants and exports for the table definations
# ---------------------------------------------------------------------

{

    my @tags;
    my $name;
    my @parts;
    my $exports;
    my $constants;
    my $modules = Class::Inspector->subclasses('UNIVERSAL');

    foreach my $module (@$modules) {

        if ($module =~ m/XAS::Model::Database::/) {

            @parts = split('::', $module);
            $name = join('', splice(@parts, 3, $#parts));
            push(@tags, $name);
            $constants->{$name} = $module;

        }

    }

    $exports = {
        any => \@tags,
        tags => {
            all => \@tags,
        }
    };

    class->constant($constants) if (defined($constants));
    class->exports($exports)    if (scalar(@tags) > 0);

}

# ---------------------------------------------------------------------
# Methods
# ---------------------------------------------------------------------

sub filter_loaded_credentials {
    my ($class, $config, $connect_args) = @_;

    $config->{dbi_attr}->{AutoCommit} = 1;
    $config->{dbi_attr}->{PrintError} = 0;
    $config->{dbi_attr}->{RaiseError} = 1;

    if ($config->{dsn} =~ m/SQLite/ ) {

        $config->{dbi_attr}->{sqlite_use_immediate_transaction} = 1;
        $config->{dbi_attr}->{sqlite_see_if_its_a_number} = 1;
        $config->{dbi_attr}->{on_connect_call} = 'use_foreign_keys';

    }

    $config->{dsn} = "dbi:$config->{dsn}:dbname=$config->{name}";

    return $config;

}

sub opendb {
    my $class = shift;

    return $class->connect(@_);

}

sub dbix_exceptions {
    my $error = shift;

    $error =~ s/dbix.class error - //;

    my $ex = Badger::Exception->new(
        type => 'dbix.class',
        info => sprintf("%s", $error)
    );

    $ex->throw;

}

1;

__END__

=head1 NAME

XAS::Model::Database - Define the database schema used by the XAS environment

=head1 SYNOPSIS

  use XAS::Model::Database 'Nmon';

  try {

      $schema = XAS::Model::Database->opendb('database');

      my @rows = Master->search($schema);

      foreach my $row (@rows) {

          printf("Hostname = %s\n", $row->Hostname);

      }

  } catch {

      my $ex = $_;

      print $ex;

  };

=head1 DESCRIPTION

This modules loads the necessary table definations for the XAS  
environment. It also exports symbols that allows the shortcut methods from 
XAS::Model::DBM to work. Please see EXPORT for those variables. This module 
can be loaded in several differant ways.

Example

    use XAS::Model::Database 'Master';

    or

    use XAS::Model::Database qw( Master Detail );

    or

    use XAS::Model::Database ':all';

The difference is that in the first example you are only loading the 
"Master" symbol into your module. The second example loads the symbols 
"Master" and "Detail". The "all" qualifer would export all defined symbols.

=head1 METHODS

=head2 opendb($database)

This method provides the defaults necessary to call the DBIx::Class::Schema 
connect() method. It takes one parameter.

=over 4

=item B<$database>

The name of a configuration item suitable for DBIx::Class::Schema::Configure.

Example

    my $handle = XAS::Model::Database->opendb('database');

=back

=head1 EXPORT

The following symbols can be exported.

 Alert - XAS::Model::Database::Alert

=head1 SEE ALSO

 DBIx::Class

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

Kevin Esteb, E<lt>kevin@kesteb.usgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
