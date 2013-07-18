#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2013 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       xas-supervisor.pl
#
# FACILITY:    XAS Application Framework
#
# ABSTRACT:    This procdure will load and supervise other processes.
#
# ENVIRONMENT: Linux - Perl 5.8.8
#
# PARAMETERS:
#              --address   The address to listen on.
#              --port      The port to listen too.
#              --cfgfile   A configuration file.
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
# 0.01         Kevin Esteb                                         07-Jul-2013
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Base::Supervisor;

main: {

    my $app = XAS::Apps::Base::Supervisor->new(
        -throws  => 'xas-collector',
        -options => [
            { 'address=s' => '127.0.0.1' },
            { 'port=s'    => '9505' },
            { 'cfgfile=s' => '' }
        ]
    );

    exit $app->run();

}

__END__

=head1 NAME

xas-supervisor.pl - Supervise other processes in the XAS environment

=head1 SYNOPSIS

xas-supervisor.pl [--help] [--debug] [--manual] [--version]

 options:

   --adress   the address to listen on
   --port     the port to listen too
   --cfgfile  the configuration file
   --logfile  the log file to use
   --pidfile  the pid file to use
   --daemon   too daemonize
   --debug    toggles debugging output
   --help     outputs simple help text
   --manual   outputs the procedures manual
   --version  outputs the apps version

=head1 DESCRIPTION

This procdure will load and supervisor other processes.

=head1 OPTIONS AND ARGUMENTS

=over 4

=item B<--address>

The address to listen on.

=item B<--port>

The port to listen too.

=item B<-cfgfile>

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

=item B<-[no]alerts>

Wither to issues alerts when problems occur.

=back

=head1 EXIT CODES

 0 - success
 1 - failure
 2 - already running

=head1 SEE ALSO

 XAS::Apps::Base::Supervisor

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
