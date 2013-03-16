package XAS::Docs::Startup;

our $VERSION = '0.02';

1;

__END__
  
=head1 NAME

XAS::Docs::Startup - how to startup the XAS environment

=head1 SYSTEM STARTUP

The message queue and the database should be installed on a system with the
resources needed to handle them. Once they are installed and started, the 
following can be completed.

=head2 Startup Scripts

Thy are located in /opt/xas/init.d. They start the  various daemons that run 
in the background. They need to either be linked or copied to the approbiate
locations. On Debian this would be /etc/init.d. Running update-rc.d will 
then activate them. The following scripts are provided:

=over 4

=item B<xas-alerts.debian>

This process scans the database looking for unhandled alerts. If any are found
an email is sent off to the approbiate people.

=item B<xas-collector.debian>

This process monitors the queues on the message queue server. When messages 
arrive they are processed and stored in the database.

=item B<xas-spooler.debian>

This process monitors the spool directories. When a spool file appears 
they are processed and sent to the message queue server.

=back

If you are not on a Debian derived system you will need to port these 
startup scripts to your platform. Contributions are greatfully accepted, 
expecially if you know of a way to reliably detect Linux distributions. 

When this has been done, and the scripts are ran the basic system is now up 
and running. These procedures will process and provide notifications on any 
alerts that may be generated.

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
