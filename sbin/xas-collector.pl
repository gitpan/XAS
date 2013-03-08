#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2010 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       xas-collector.pl
#
# FACILITY:    XAS Application Framework
#
# ABSTRACT:    This procdure will collect alert data from the message queue
#              and store it into a database.
#
# ENVIRONMENT: Linux - Perl 5.8.8
#
# PARAMETERS:  --host      Where the Message Queue server resides.
#              --port      The port for that server.
#              --configs   A configuration file.
#              --logfile   The log file to use.
#              --pidfile   The pid file to use.
#              --daemon    Run as a daemon.
#              --help      Print this help message.
#              --manual    Print the documentation for the prodecure.
#              --version   Print out the version number.
#              --debug     Toggles debugging output.
#
# RETURNS:     0 - success
#              1 - failure
#              2 - already running
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         12-Mar-2012
#
# 0.02         Kevin Esteb                                         08-Aug-2012
#              Updated to the new app framework.
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Base::Collector;

main: {

    my $app = XAS::Apps::Base::Collector->new(
        -throws  => 'xas-collector',
        -options => [
            { 'host=s'    => '' },
            { 'port=s'    => '' },
            { 'configs=s' => '' }
        ]
    );

    exit $app->run();

}

__END__

=head1 NAME

xas-collector.pl - Collects alerts for the XAS environment

=head1 SYNOPSIS

xas-collector.pl [--help] [--debug] [--manual] [--version]

 options:

   --host     where the Message Queue server resides
   --port     the port for that server
   --configs  the configuration file
   --logfile  the log file to use
   --pidfile  the pid file to use
   --daemon   too daemonize
   --debug    toggles debugging output
   --help     outputs simple help text
   --manual   outputs the procedures manual
   --version  outputs the apps version

=head1 DESCRIPTION

This procdure will collect alert data from the message queue and store 
it into a database.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--host>

Where the Message Queue server resides.

=item B<--port>

The port for that server.

=item B<-configs>

The configuration file to use.

=item B<--logfile>

The log file to use.

=item B<--pidfile>

the pid file to use.

=item B<--daemon>

Run as a daemon.

=item B<--debug>

Turns on debbuging.

=item B<--help>

Displays a simple help message.

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

 XAS::Apps::Base::Collector

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
