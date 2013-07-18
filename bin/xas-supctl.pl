#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2012 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       xas-supctl.pl
#
# FACILITY:    XAS
#
# ABSTRACT:    A simple command line client for XAS supverisor
#
# ENVIRONMENT: Linux/AIX Perl Environment
#
# PARAMETERS:  
#              --port    the port to use
#              --host    the host the server resides on
#              --start   issue a 'start' command
#              --stop    issue a 'stop' command
#              --reload  issue a 'reload' command
#              --status  issue a 'status' command
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
# 0.01         Kevin Esteb                                         09-Jul-2013
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Base::Supctl;

main: {

    my $app = XAS::Apps::Base::Supctl->new(
        -throws => 'xas-supctl',
        -options => [
            { 'port=s',   '9505' },
            { 'host=s',   'localhost' },
            { 'start=s',  undef },
            { 'stop=s',   undef },
            { 'status=s', undef },
            { 'reload=s', undef },
        ]
    );

    exit $app->run();

}

__END__

=head1 NAME

xas-supctl.pl - a simple command line interface to the XAS supervisor

=head1 SYNOPSIS

xas-supctl.pl [--help] [--debug] [--manual] [--version] [--stop <name>]

 options:
   --port       the port to use
   --host       the host the server resides on
   --start      issue a 'start' command for managed process
   --stop       issue a 'stop' command for a managed process
   --reload     issue a 'reload' command for a managed process
   --status     issue a 'status' command for a managed process
   --help       outputs simple help text
   --manual     outputs the procedures manual
   --version    outputs the apps version
   --debug      toogles debugging output
   --[no]alerts toogles alert notification

=head1 DESCRIPTION

This procedure is a simple command line interface to the XAS supervisor.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--host>

The host the supervisor resides on.

=item B<--port>

The port it is listening too.

=item B<--stop>

This issues a 'stop' command to the supervisor.

=item B<--start>

This issues a 'start' command to the supervisor.

=item B<--status>

This issues a 'status' command to the supervisor.

=item B<--reload>

This issues a 'reload' command to the supervisor.

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

 XAS::Apps::Base::Supctl

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
