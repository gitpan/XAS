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

They are located in /etc/init.d. They start the various daemons that run 
in the background. On Debian, running update-rc.d will then activate them.

At this point you need to decide how you want the environment to run. You
can use xas-supervisor.pl to start and run the rest of the daemons or you
can run them individually. There are advantages with either way. I would
suggest running under the supervisor. 

The following scripts are provided:

=over 4

=item B<xas-alerts>

This process scans the database looking for unhandled alerts. If any are found
an email is sent off to the approbiate people.

=item B<xas-collector>

This process monitors the queues on the message queue server. When messages 
arrive they are processed and stored in the database.

=item B<xas-spooler>

This process monitors the spool directories. When a spool file appears 
they are processed and sent to the message queue server.

=item B<xas-supervisor>

This is a process that starts and monitors other processes.

=back

If you are not on a Debian derived system you will need to port these 
startup scripts to your platform. Contributions are greatfully accepted, 
expecially if you know of a way to reliably detect Linux distributions. 

When this has been done, and the scripts are ran the basic system is now up 
and running. These procedures will process and provide notifications on any 
alerts that may be generated.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
