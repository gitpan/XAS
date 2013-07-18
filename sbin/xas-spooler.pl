#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2012 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       xas-spooler.pl
#
# FACILITY:    The XAS Environment
#
# ABSTRACT:    This procdure will monitor spool directories looking for 
#              spool files to send to the message queue.
#
# ENVIRONMENT: Linux - Perl v5.8.8
#
# PARAMETERS:  --host      Where the Message Queue server resides.
#              --port      The port for that server.
#              --configs   The config file to use.
#              --logfile   The log file to use.
#              --pidfile   The pid file to use.
#              --daemon    Run as a daemon.
#              --help      Print this help message.
#              --manual    Prints out the procedures manual
#              --version   Prints out the apps version
#              --debug     Toggles debugging output.
#
# RETURNS:     0 - success
#              1 - failure
#              2 - already running
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         07-Jul-2010
#
# 0.02         Kevin Esteb                                         09-Aug-2012
#              Updated to the new app framework.
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Base::Spooler;

main: {

    my $app = XAS::Apps::Base::Spooler->new(
        -throws   => 'xas-spooler',
        -facility => 'xas',
        -options => [
            { 'host=s'    => 'localhost' },
            { 'port=s'    => '61613' },
            { 'configs=s' => '' },
        ]
    );

    exit $app->run();

}

__END__
  
=head1 NAME

xas-spooler.pl - A procedure to process spool files for the XAS Environment.

=head1 SYNOPSIS

xas-spooler.pl [--help] [--debug] [--manual] [--version]

 options:
   --host     where the Message Queue server resides
   --port     the port for that server
   --configs  the config file to use
   --logfile  the log file to use
   --pidfile  the pid file to use
   --help     outputs simple help text
   --manual   outputs the procedures manual
   --version  outputs the apps version
   --debug    toogles debugging output

=head1 DESCRIPTION

This procedure will process spool files and send them to the message
queue server.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--host>

Where the Message Queue server resides.

=item B<--port>

The port that the server listens on.

=item B<--config>

The config file to use.

=item B<--logfile>

The log file to use.

=item B<--pidfile>

The pid file to use.

=item B<--help>

Displays a simple help message.
  
=item B<--debug>

Turns on debbuging.

=item B<--manual> 

The complete documentation.
  
=item B<--version>

Prints out the apps version

=back

=head1 EXIT CODES

 0 - success
 1 - failure
 2 - already running

=head1 SEE ALSO

 XAS::Apps::Base::Spooler

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
