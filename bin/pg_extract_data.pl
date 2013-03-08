#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2012 Kevin L. Esteb. All Rights Reserved
#
#
# TITLE:       pg_extract_data.pl
#
# FACILITY:    XAS application system
#
# ABSTRACT:    This procedure will extract specific data from "copy"
#              statements in a postgres pg_dumpall file.
#
# ENVIRONMENT: XAS Perl Environment
#
# PARAMETERS:  --help     prints out a helpful help message
#              --debug    toggles debug output
#              --file     the database backup file to use
#              --table    the wanted tables data
#              --schema   the schema the table is in
#
# RETURNS:
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         29-May-2012
#
# 0.02         Kevin Esteb                                         08-Aug-2012
#              Updated to the new app framework.
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Base::ExtractData;

main: {

    my $app = XAS::Apps::Base::ExtractData->new(
        -throws  => 'pg_extract_data',
        -options => [
            {'file=s'   => ''},
            {'table=s'  => ''},
            {'schema=s' => ''}
        ]
    );

    exit $app->run();

}

__END__

=head1 NAME

pg_extract_data.pl - Extract data from a PostgreSQL dump file

=head1 SYNOPSIS

pg_extract_data.pl [--help] [--debug] [--manual] [--version]

 options:
   --file       the postgres dump file
   --table      the tabel to extract data from
   --schema     the schema the table is in
   --help       outputs simple help text
   --manual     outputs the procedures manual
   --version    outputs the apps version
   --debug      toogles debugging output
   --[no]alerts toggles alert notification

=head1 DESCRIPTION

This procedure will extract the data from a postgres dump file. The data that is
extracted is based on the table and its schema.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<-file>

The postgres dump file.

=item B<-table>

The table that data resides in.

=item B<-schema>

The schema the table resides in.

=item B<--help>

Displays a simple help message.

=item B<--debug>

Turns on debbuging.

=item B<--alerts>

Togggles alert notification. The default is on. 

=item B<--manual>

The complete documentation.
  
=item B<--version>

Prints out the apps version

=back

=head1 EXIT CODES

 0 - success
 1 - failure

=head1 SEE ALSO

 XAS::Apps::Base::ExtractData

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
