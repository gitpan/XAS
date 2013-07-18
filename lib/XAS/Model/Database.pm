package XAS::Model::Database;

our $VERSION = '0.01';

use XAS::Exception;
use Class::Inspector;

use XAS::Class
  version    => $VERSION,
  base       => 'DBIx::Class::Schema::Config XAS::Base',
  import     => 'class CLASS',
  constants  => 'DELIMITER PKG REFS ONCE',
  filesystem => 'File',
  exports => {
    hooks => {
        schema => \&schema,
        table  => \&tables,
        tables => \&tables,
    }
  },
  vars => {
    TABLES => {}
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

# ---------------------------------------------------------------------
# Define DBIx::Class::Schema::Config configuration file locations
#
# Format of the configuration file is as follows:
#
# [progress]             - corresponds to what is given to opendb()
# dbname = monitor       - name of the database
# dsn = SQLite           - corresponds to the dbd driver
# username = username    - the user context to use
# password = password    - the password for that context
#
# When using ODBC with a user level DSN or a dynamic connection, you
# should add the following items:
#
# driver = SQL Server
# server = localhost,1234
#
# When using PostgresSQL (Pg), you can add the following items:
#
# port = 5432
# host = localhost
# sslmode = something
# options = something
#
# Or a service name, which is not compatiable with the above.
#
# service = service name
# 
# There can be multiple stanzas, the first one that matches is used.
# ---------------------------------------------------------------------

{
    # -----------------------------------------------------------------
    # Defining where our database.ini file could be
    # -----------------------------------------------------------------

    my $path;

    if ($^O eq "MSWin32") {

        $path = defined($ENV{XAS_ROOT}) ? $ENV{XAS_ROOT} : 'D:\\';

        CLASS->config_paths([(
            File($path, 'etc', 'database')->path,
            File($ENV{USERPROFILE}, 'database')->path,
        )]);

    } else {

        $path = defined($ENV{XAS_ROOT}) ? $ENV{XAS_ROOT} : '/opt';

        CLASS->config_paths([(
            File($path, 'etc', 'database')->path,
            File($ENV{HOME}, '.database')->path,
        )]);

    }

}

# ---------------------------------------------------------------------
# Defining our DBIx::Class exception handler
# ---------------------------------------------------------------------

CLASS->exception_action(\&XAS::Model::Database::dbix_exceptions);

# ---------------------------------------------------------------------
# Hooks
# ---------------------------------------------------------------------

sub tables {
    my ($class, $target, $symbol, $values) = @_;

    my $value  = shift(@$values);
    my @tables = split(DELIMITER, $value);

    foreach my $table (@tables) {

        if ($table ne ':all') {

            if (defined($TABLES->{$table})) {

                no strict REFS;
                no warnings ONCE;

                *{$target.PKG.$table} = sub {$TABLES->{$table}};

            } else {

                $class->throw("$table is not exported by $class");

            }

        } else {

            while (my ($key, $value) = each(%$TABLES)) {

                no strict REFS;
                no warnings ONCE;

                *{$target.PKG.$key} = sub {$value};

            }

            last;

        }

    }

}

sub schema {
    my ($class, $target, $symbol, $values) = @_;

    my $name;
    my $begin;
    my @parts;
    my $modules;
    my $namespace = shift(@$values);
    my $pattern = $namespace . '::';

    # loading our schema

    CLASS->load_namespaces(result_namespace => "+$namespace");

    # building our TABLES hash

    $modules = Class::Inspector->subclasses('UNIVERSAL');

    foreach my $module (@$modules) {

        if ($module =~ m/$pattern/) {

            @parts = split('::', $module);
            $begin = scalar(@parts) - 1;
            $name = join('', splice(@parts, $begin, $#parts));

            $TABLES->{$name} = $module;

        }

    }

}

# ---------------------------------------------------------------------
# Methods
# ---------------------------------------------------------------------

sub filter_loaded_credentials {
    my ($class, $config, $connect_args) = @_;

    $config->{dbi_attr}->{AutoCommit} = 1;
    $config->{dbi_attr}->{PrintError} = 0;
    $config->{dbi_attr}->{RaiseError} = 1;

    if ($config->{dsn} eq 'SQLite') {

        $config->{dbi_attr}->{sqlite_use_immediate_transaction} = 1;
        $config->{dbi_attr}->{sqlite_see_if_its_a_number} = 1;
        $config->{dbi_attr}->{on_connect_call} = 'use_foreign_keys';

        $config->{dsn} = "dbi:$config->{dsn}:dbname=$config->{dbname}";

    } elsif ($config->{dsn} eq 'ODBC') {

        # http://dolio.lh.net/~apw/doc/HOWTO/HOWTO-Connect_Perl_to_SQL_Server.pdf
        #
        # a user level DSN or a dynamic connection needs the following:
        #
        # dbi:ODBC:Driver={driver};Server=server;Database=dbname
        #
        # a system level DSN needs the following:
        #
        # dbi:ODBC:dbname
        # 

        if (defined($config->{driver})) {

            $config->{dsn} = sprintf(
                "dbi:%s:Driver={%s};Database=%s;Server=%s",
                $config->{dsn}, $config->{driver},
                $config->{dbname}, $config->{server}
            );

        } else {

            $config->{dsn} = "dbi:$config->{dsn}:$config->{dbname}";
   
        }

    } elsif ($config->{dsn} eq 'Pg') {

        unless (defined($config->{service})) {

            $config->{dsn}  = "dbi:$config->{dsn}:dbname=$config->{dbname}";
            $config->{dsn} .= ";host=$config->{host}" if (defined($config->{host}));
            $config->{dsn} .= ";port=$config->{port}" if (defined($config->{port}));
            $config->{dsn} .= ";options=$config->{options}" if (defined($config->{options}));
            $config->{dsn} .= ";sslnode=$config->{sslmode}" if (defined($config->{sslmode}));

        } else {

            $config->{dsn} = "dbi:$config->{dsn}:service=$config->{service}";

        }

    } else {

        $config->{dsn} = "dbi:$config->{dsn}:dbname=$config->{dbname}";

    }

    return $config;

}

sub opendb {
    my $class = shift;

    return $class->connect(@_);

}

sub dbix_exceptions {
    my $error = shift;

    $error =~ s/dbix.class error - //;

    my $ex = XAS::Exception->new(
        type => 'dbix.class',
        info => sprintf("%s", $error)
    );

    $ex->throw;

}

1;

__END__

=head1 NAME

XAS::Model::Database - A class to load database schemas

=head1 SYNOPSIS

  use XAS::Model::Database
    schema => 'ETL::Model::Database',
    table  => 'Master';

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

This module loads DBIx::Class table definations and defines a path for
the database.ini configuration file. It can also load shortcut constants
for table definations. 

Example

    use XAS::Model::Database
      schema => 'ETL::Model::Database',
      table  => 'Master'
    ;

    or

    use XAS::Model::Database
      schema => 'ETL::Model::Database',
      tables => qw( Master Detail )
    ;

    or

    use XAS::Model::Database
      schema => 'ETL::Model::Database',
      table => ':all'
    ;

The difference is that in the first example you are only loading the 
"Master" constant into your module. The second example loads the constants 
"Master" and "Detail". The ":all" qualifer would load all the defined
constants. 

=head1 HOOKS

The following hooks are defined to load table definations and define
constants. The order that they are called is important, i.e. 'schema' must
come before 'table'.

=head2 schema

This defines a load path to the modules that defines a database schema.
DBIx::Class loads modules based on the path. For example all modules
below 'ETL::Model::Database' will be loaded at once. You can be more
specific. If you only want the 'Progress' database schema you can load
it by using 'ETL::Model::Database::Progress'.
 
=head2 table

This will define a constant for a table defination. This constant is based
on the table name, which is defined by the modules name. So the module
'ETL::Model::Database::Progress::ActOther' will have a constant named
'ActOther' that refers to the module.

=over 4

=item Warning

If you have multiple tables named the same thing in differant schemas
and load all the schemas at once, this constant will refer to the last
loaded table defination.

=back

=head2 tables

Does the same thing as 'table'.

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

=head1 SEE ALSO

=over 4

=item DBIx::Class

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
