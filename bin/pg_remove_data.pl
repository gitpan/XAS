#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2012 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       pg_remove_data.pl
#
# FACILITY:    XAS application system
#
# ABSTRACT:    This procedure will cut out database sections from
#              a postgress pg_dumpall file.
#
# ENVIRONMENT: XAS Perl Environment
#
# PARAMETERS:  --help     prints out a helpful help message
#              --debug    toggles debug output
#              --file     the database backup file to use
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
use XAS::Apps::Base::RemoveData;

main: {
    
    my $app = XAS::Apps::Base::RemoveData->new(
        -throws  => 'pg_remove_data',
        -options => [
            {'file=s' => ''},
        ]
    );

    exit $app->run();

}

__END__

=head1 NAME

pg_remove_data.pl - Remove data from a PostgreSQL dump file

=head1 SYNOPSIS

pg_remove_data.pl [--help] [--debug] [--manual] [--version]

 options:
   --file       the postgres dump file
   --help       outputs simple help text
   --manual     outputs the procedures manual
   --version    outputs the apps version
   --debug      toogles debugging output
   --[no]alerts toogles alert notification

=head1 DESCRIPTION

This procedure will remove the "copy" statements from a pg_dumpall backup.
Sending the resulting output to stdout.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<-file>

The postgres dump file.

=item B<--help>

Displays a simple help message.

=item B<--debug>

Turns on debbuging.

=item B<--manual> 

The complete documentation.
  
=item B<--version>

Prints out the apps version

=item B<--alerts>

Toggles alert notification. The default is on.

=back

=head1 EXIT CODES

 0 - success
 1 - failure

=head1 SEE ALSO

 XAS::Apps::Base::RemoveData

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
