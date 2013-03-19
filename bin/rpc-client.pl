#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2012 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       rpc-client.pl
#
# FACILITY:    XAS
#
# ABSTRACT:    A simple command line client for a rpc server
#
# ENVIRONMENT: Linux/AIX Perl Environment
#
# PARAMETERS:  
#              --port    the port to use
#              --host    the host the server resides on
#              --list    issue a 'list' command
#              --status  issue a 'status' command
#              --echo    issue a 'echo' command
#              --help    prints out a helpful help message
#              --manual  prints out the procedures manual
#              --version prints out the procedures version
#              --debug   toggles debug output
#
# RETURNS:     0 - success
#              1 - failure
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         02-Apr-2009
#
# 0.02         Kevin Esteb                                         10-Jul-2012
#              Updated the help/version/manual switches to use
#              pod for the output text.
#
# 0.03         Kevin Esteb                                         08-Aug-2012
#              Changed over to the new app framework.
#
# ============================================================================
#

use lib "../lib";
use XAS::Constants 'TRUE FALSE';
use XAS::Apps::Test::RPC::Client;

main: {

    my $app = XAS::Apps::Test::RPC::Client->new(
        -throws => 'rpc-client',
        -options => [
            { 'port=s', '9507' },
            { 'host=s', 'localhost' },
            { 'list',   FALSE },
            { 'status', FALSE },
            { 'echo=s', '' }
        ]
    );

    exit $app->run();

}

__END__

=head1 NAME

rpc-client.pl - a simple command line rpc client

=head1 SYNOPSIS

rpc-client.pl [--help] [--debug] [--manual] [--version]

 options:
   --port       the port to use
   --host       the host the server resides on
   --list       issue a 'list' command
   --status     issue a 'status' command
   --echo       issue a 'echo' command
   --help       outputs simple help text
   --manual     outputs the procedures manual
   --version    outputs the apps version
   --debug      toogles debugging output
   --[no]alerts toogles alert notification

=head1 DESCRIPTION

This procedure is a simple template to help write standardized procedures.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--host>

The host the echo server resides on.

=item B<--port>

The port it is listening on.

=item B<--list>

This issues a 'list' command to the rpc server.

=item B<--status>

This issues a 'status' command to the rpc server.

=item B<--echo>

This issues a 'status' command to the rpc server.

=item B<--help>

Displays a simple help message.

=item B<--debug>

Turns on debbuging.

=item B<--alerts>

Toggles alert notification. The default is on.

=item B<--manual> 

The complete documentation.
  
=item B<--version>

Prints out the apps version

=back

=head1 EXIT CODES

 0 - success
 1 - failure

=head1 SEE ALSO

 XAS::Apps::Templates::Generic

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
