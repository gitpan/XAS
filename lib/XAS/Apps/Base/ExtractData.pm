package XAS::Apps::Base::ExtractData;

our $VERSION = '0.01';

use Try::Tiny;
use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::App',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub parse_file {
    my $self = shift;

    my $fh;
    my $table = $self->table;
    my $schema = $self->schema;

    open($fh, "<", $self->file);

    while (<$fh>) {

        if ($_ =~ m/^COPY $table \(/ ) {

            printf("SET search_path = %s, pg_catalog;\n", $schema);
            print $_;

            while (<$fh>) {

                print $_;

                return if ($_ =~ m/^\\\./);

            }

        }

    }

}

sub main {
    my $self = shift;

    $self->log->debug('Starting main section');

    $self->parse_file();

    $self->log->debug('Ending main section');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Base::ExtractData - This module will extract data from a postgres dump file

=head1 SYNOPSIS

 use XAS::Apps::Base::ExtractData;

 my $app = XAS::Apps::Base::ExtractData->new(;
    -throws  => 'pg_extract_data',
    -options => [
        {'file=s'   => ''},
        {'table=s'  => ''},
        {'schema=s' => ''}
    ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will extract the "copy" statements from a postgres pg_dumpall file.
This is based on the table name. This data is then suitable to populate
an "empty" database that already has a schema defined. This allows 
you to do selective restores.

=head1 CONFIGURATION

The following parameters are used to configure the module.

=head2 -options

Defines the command line options for this module. 

=over 4

=item B<'files=s'>

Defines the dump file to use.

=item B<'table=s'>

Defines which table to extract data from.

=item B<'schema=s'>

Defines the database schema to use.

=back

=head1 SEE ALSO

 bin/pg_extract_data.pl

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
