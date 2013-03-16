package XAS::Docs::Objectives;

our $VERSION = '0.01';

1;

__END__
  
=head1 NAME

XAS::Docs::Objectives - the why of the XAS environment

=head1 OBJECTIVES

After working on several large systems, writing similar code, it becomes 
obvious that certain standards need to be implemented if the system is to 
be maintainable. These are the objectives that XAS is striving for.

=head2 Environment

The operating environment is abstracted away with L<XAS::System::Environment>.
By default, in a UNIX/Linux environment, everything resides under /opt/xas. 
This default can be changed upon initial installation. Additonal changes can
be made using environment variables. On a Linux system they are defined in
/etc/profile.d/xas.sh. Every path used within the system can be configured 
with a environment variable.

=head2 Option Handling

Any good system needs consistent option handling. This is handled by 
L<XAS::Lib::App> for command line procedures and by L<XAS::Lib::App::Daemom>
for daemons. Every procedure has the following options available:

=over 4
 
=item B<--version>

Display the procedures version number.

=item B<--help>

Display a short help screen on available options and there usage.

=item B<--man>

Displays detailed documentation on the procedure.

=item B<--debug>

Toggle debugging output.

=item B<--[no]alert>

Toggles wither alerts are send. By default they are.

=back

Daemons have this additional options.

=over 4

=item B<--logfile>

Override the default log file.

=item B<--pidfile>

Override the default pid file.

=item B<--daemon>

Wither to detach from the controlling terminal. Default is to not too.

=back

Additional options can be easily added to the application as needed.

=head2 Parameter Handling

Consistent parameter handling for modules is important. Every public facing
sub routine uses named parameters if there are more then two passed being 
passed. Each parameter is validated using L<Params::Validate|Params::Validate> 
and will throw an exception when validation fails.

=head2 Exception Handling

Every module will throw exceptions using L<XAS::Exception|XAS::Exception>. 
They use a consitent naming convention, which will lead you to the offending
routine. All command line programs will return 0 for success and 1 for error. 
Daemons can also return a 2 for 'process already running'. Every program has 
a global exception handler. If an exception is not handled, this will issue 
an alert and return the appropiate error code. Alerts can be turned off with 
the use of --noalert option.

=head2 Logging

All procedures use the same logging module L<XAS::System::Logging>. This 
module produces a consistent format that is the same wither the logging 
is to stderr or to a log file. This format is easy to parse when you want 
to extract information. The format is as follows:

 [YYYY-MM-DD HH:MM:SS] <level> - <message>

And the following levels are defined: INFO, WARN, ERROR, FATAL and DEBUG

=head2 Communications

Communications are important within a distributed application. This system 
uses a message queue. The message queue needs to be STOMP v1.0 compatiable. 
RabbitMQ and POE::Component::MessageQueue have been tested. All messaging 
uses the tried and true, store and forward strategy. The message queues 
themselves should be configured to store messages on disk when a large 
backlog happens. Using this methodology ensures that messages are not lost. 
The messages themselves are in a standard JSON format. When a message queue 
won't work, a RPC mechanism using JSONRPC v2.0 has been defined. An effort 
has been made to use standard text based protocals so that other systems 
and languages can easily intergrate with this one.

=head2 Notifications

Notifications are important within a distributed application. It allows you to
know what is happening within the system. There are two different ways to 
send notifications. By email L<XAS::System::Email> and by alerts L<XAS::System::Alert>. 
Alerts are stored within a database and use the message queue for transport.
Emails use an external mail system. Alerts can be processed by a management 
console. This allows for a response to problems. They can also be organized 
and reported on. Which can make manegement types happy.

=head2 Database

All access to the database uses L<DBIx::Class>. This system has been tested 
against SQLite and PostgreSQL. Using DBIx::Class allows the system to be
database agnostic. 

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
