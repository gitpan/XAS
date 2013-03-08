package XAS;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

XAS - A framework for distributed applicatons

=head1 DESCRIPTION

Frameworks mean differant things to differant people. In this case we are
trying to present a consistent environment, option handling, logging,
communications, notifications and database access in distributed applications. 

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
for daemons. Everything has the basic options of --version, --help, --man, 
--alert and --debug. Daemons add options for --logfile, --pidfile and --daemon.
These override defaults defined by the environment. Additional options can 
be easily added to the application as needed.

=head2 Exception Handling

Every module will throw exceptions using L<XAS::Exception>. They use a 
consitent naming convention. All command line programs will return 0 for 
success and 1 for error. Daemons can also return a 2 for 'process already 
running'. Every program has a global exception handler. If an exception is
not handled, this will issue an alert and return the appropiate error code.
Alerts can be turned off with the use of --noalert option.

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

=back

=head2 Database Initialization

The procedure /opt/xas/bin/create_schema.pl is used to create the 
database schema. How to load the schema into your database system 
is dependent on that system. Additional help can be had with 
/opt/xas/bin/create_schema.pl --man .

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

=back

If you are not on a Debian derived system you will need to port these 
startup scripts to your platform. Contributions are greatfully accepted, 
expecially if you know of a way to reliably detect Linux distributions. 

When this has been done, and the scripts are ran the basic system is now up 
and running. These procedures will process and provide notifications on any 
alerts that may be generated.

=head1 WHAT NOW?

Wow, you have a running system, now what do you do with it. As stated above
this system is a framework. It dosen't do anything on it's own. You need to 
write the code to do somethimg useful. The tools are provided and examples are
available. 

=head1 SEE ALSO

 XAS::Base
 XAS::Class
 XAS::Constants
 XAS::Exception
 XAS::System
 XAS::Utils

 XAS::Apps::Base::Alerts
 XAS::Apps::Base::Collector
 XAS::Apps::Base::ExtractData
 XAS::Apps::Base::ExtractGlobals
 XAS::Apps::Base::RemoveData
 XAS::Apps::Database::Schema
 XAS::Apps::Templates::Daemon
 XAS::Apps::Templates::Generic
 XAS::Apps::Test::Echo::Client
 XAS::Apps::Test::Echo::Server
 XAS::Apps::Test::RPC::Client
 XAS::Apps::Test::RPC::Methods
 XAS::Apps::Test::RPC::Server

 XAS::Collector::Alert
 XAS::Collector::Base
 XAS::Collector::Connector
 XAS::Collector::Factory

 XAS::Lib::App
 XAS::Lib::App::Daemon
 XAS::Lib::App::Daemon::POE
 XAS::Lib::Connector
 XAS::Lib::Counter
 XAS::Lib::Daemon::Logger
 XAS::Lib::Daemon::Logging
 XAS::Lib::Gearman::Admin
 XAS::Lib::Gearman::Admin::Status
 XAS::Lib::Gearman::Admin::Worker
 XAS::Lib::Gearman::Client
 XAS::Lib::Gearman::Client::Status
 XAS::Lib::Gearman::Worker
 XAS::Lib::Net::Client
 XAS::LIb::Net::Server
 XAS::Lib::RPC::JSON::Client
 XAS::Lib::RPC::JSON::Server
 XAS::Lib::Session
 XAS::Lib::Spool

 XAS::Model::Database
 XAS::Model::Database::Alert
 XAS::Model::Database::Counter
 XAS::Model::DBM

 XAS::Monitor::Base
 XAS::Monitor::Database
 XAS::Monitor::Database::Alert

 XAS::Scheduler::Base

 XAS::System::Alert
 XAS::System::Email
 XAS::System::Environment
 XAS::System::Logger

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
