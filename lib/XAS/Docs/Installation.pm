package XAS::Docs::Installation;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Installation - how to install the XAS environment

=head1 INSTALLATION

To install this system, run the following commands:

     perl Build.PL
     ./Build
     ./Build test
     ./Build install

On a Linux system this will install the software in /opt/xas. This can
be overridden with the --install_base option to Build.PL. 

This installation also creates a "xas" user and group. This is used to
set permissions on files and for user context while running daemons.

The installation also asked where your message queue and email system reside 
and what ports they are listening on.

=head1 ADDITIONAL INSTALLS

This system uses a message queue server and a database system. The intallation
of either is beyond the scope of this document.

=head1 SEE ALSO

 XAS

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
