package XAS::Docs::Installation;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Installation - how to install the XAS environment

The installation will ask where your message queue and email system reside 
and what ports they are listening on. To install this module, run the 
following commands:

	# perl Build.PL
	# ./Build
	# ./Build test
	# ./Build install
    # ./Build post_install

On a Linux system this will install the software into /opt/xas. This can
be overridden with the --install_base option to Build.PL. 

You can also use the debian package manager to install this software. Use the
following commands to do so:

    # debuild -uc -us
    # dpkg -i ../libxas-base-perl_0.05-1_all.deb

This will install the software into /opt/xas. This package uses CPAN
modules that may not be supported from the debian repositories. 

=head2 WARNING

These installation instructions presupposes some sort of Linux box.
Persumably a Debian based distribution. The perl based installation
steps will work on Redhat based distributions. They will also work,
to a certain extent, on generic Unix based systems. With these, the 
specialized startup scripts will need to be modified to work on them.
This software requires Perl 5.8.8 or higher to operate.

=head1 POST INSTALLATION

This installation creates a "xas" user and group. This is used to
set permissions on files and for user context with running daemons.

A xas.sh file is created and placed in the /etc/profile.d directory to define 
environment variables for the system. 

A xas file is created and placed in the /etc/logrotate.d directory to
help manage log files.

Start up scripts for various daemons are created in /etc/init.d. Since the 
LSB is rather liberally interrupted by the various distributors, these scripts 
are for Debian based systems. Porting them to other distributions is rather
trivial and if you have a fool proof way to determine the Linux distribution,
please forward it to me. Thanks.

=head1 SAMPLE INSTALL

The following is a sample installation.

 $ perl Build.PL
 Enter your STOMP MQ Server [mq.example.com ]localhost
 Enter the STOMP MQ Port [61613 ]
 61613
 Enter your Mail Server [mail.example.com ]mail.kesteb.us
 Enter the Mail server port [25 ]
 25
 Enter this hosts name [localhost ]bob
 Enter this hosts domain [example.com ]kesteb.us
 Enter the database name [XAS ]xxx
 Enter the database user [xas ]xxx
 Enter the database users password [password ]xxx
 Enter the database DSN [Pg ]
 Pg
 Creating new 'MYMETA.yml' with configuration results
 Creating new 'Build' script for 'XAS' version '0.04'
 $
 $ ./Build
 Building XAS
 $ ./Build test
 t/00-load.t ....... 6/57 # Testing XAS::Base 0.01, Perl 5.010001, /usr/bin/perl
 t/00-load.t ....... ok
 t/boilerplate.t ... ok
 t/manifest.t ...... skipped: Author tests not required for installation
 t/pod-coverage.t .. skipped: Test::Pod::Coverage 1.08 required for testing POD coverage
 t/pod.t ........... ok
 t/spell.t ......... skipped: Author tests not required for installation
 All tests successful.

 Test Summary Report
 -------------------
 t/boilerplate.t (Wstat: 0 Tests: 3 Failed: 0)
   TODO passed:   1-3
 Files=6, Tests=194,  6 wallclock secs ( 0.21 usr  0.05 sys +  4.72 cusr  0.36 csys =  5.34 CPU)
 Result: PASS
 $
 $ su 
 # ./Build install
 # exit
 $

=head1 ADDITIONAL INSTALLS

This system uses a message queue server and a database system. The intallation
of either is beyond the scope of this document.

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
