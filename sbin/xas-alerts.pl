#!/usr/bin/perl
# ============================================================================
#             Copyright (c) 2012 Kevin L. Esteb All Rights Reserved
#
#
# TITLE:       xas-alerts.pl
#
# FACILITY:    The XAS application environment
#
# ABSTRACT:    This procedure runs in the backup ground, monitoring for
#              alerts.
#
# ENVIRONMENT: Linux Perl v5.8.8
#
# PARAMETERS:  --help      prints out a helpful help message
#              --debug     toggles debug output
#              --daemon    run as a daemon
#              --manual    prints out the procedures manual
#              --version   prints out the procedures version
#              --logfile   the log file to use
#              --pidfile   the pid file to use
#
# RETURNS:     0 - success
#              1 - failure
#              2 - already running
#
# Version      Author                                              Date
# -------      ----------------------------------------------      -----------
# 0.01         Kevin Esteb                                         13-Mar-2012
#
# 0.02         Kevin Esteb                                         08-Aug-2012
#              Updated for the new app framework.
#
# ============================================================================
#

use lib "../lib";
use XAS::Apps::Base::Alerts;

main: {

    my $app = XAS::Apps::Base::Alerts->new(
        -throws => 'xas-alerts'
    );

    exit $app->run();

}

__END__

=head1 NAME

xas-alerts.pl - A procedure to monitor the alerts for the XAS environment

=head1 SYNOPSIS

xas-alerts.pl [--help] [--debug] [--manual] [--version]

 options:
   --logfile  the log file to use
   --pidfile  the pid file to use
   --daemon   too daemonize
   --debug    toggles debugging output
   --help     outputs simple help text
   --manual   outputs the procedures manual
   --version  outputs the apps version

=head1 DESCRIPTION

This procedure will monitor the Alerts table within the database. When pending
alerts are found an email is sent off to notify somebody.

=head1 OPTIONS AND ARGUMENTS

=over 4

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

 XAS::Apps::Base::Alerts

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
