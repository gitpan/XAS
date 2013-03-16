package XAS::Docs::Configuration;

our $VERSION = '0.02';

1;

__END__
  
=head1 NAME

XAS::Docs::Configuraton - How to configure the XAS environment

=head1 CONFIGURATION

The system has a flexiable set of configuration files that can be changed to
match your environment.

=head2 Configuration Files

The following configuration files can be modified.

=over 4

=item B</etc/profile.d/xas.sh>

This file configures the environment. It sources /opt/xas/environment and
redefines the PATH and MANPATH environment variables. It is loaded into the
current shell.

=item B</opt/xas/etc/database.ini>

This file controls how the database is accessed. By default this is for SQLite.
You can consult L<DBIx::Class::Schema::Config> for additional information.

=item B</opt/xas/environment>

This file defines the environment variables that controls the system. They
can be changed to match your environment.

=item B</opt/xas/etc/xas-collector.ini>

This file is used to configure the collector. The collector is used to
retrieve messages from the message queue.

=item B</opt/xas/etc/xas-spooler.ini>

This file is used to configure the spooler. The spooler is used to
send messages to the message queue.

=back

=head2 Database Initialization

The procedure /opt/xas/bin/create_schema.pl is used to create the 
database schema. How to load the schema into your database system 
is dependent on that system. Additional help can be had with:

 /opt/xas/bin/create_schema.pl --man

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
