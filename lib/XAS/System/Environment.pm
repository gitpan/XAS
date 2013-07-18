package XAS::System::Environment;

our $VERSION = '0.01';

use File::Basename;
use Net::Domain qw(hostdomain);

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Base',
  filesystem => 'File Dir Path Cwd',
  accessors  => 'path host domain username mqserver mqport mxserver mxport',
;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    my $temp;
    my $name;
    my $path;
    my $suffix;

    $self->{config} = $config;

    # Initialize variables - these are defaults

    $self->{mqserver} = defined($ENV{XAS_MQSERVER}) ? $ENV{XAS_MQSERVER} : 'mq.example.com';
    $self->{mqport}   = defined($ENV{XAS_MQPORT}) ? $ENV{XAS_MQPORT} : '61613';

    $self->{mxserver} = defined($ENV{XAS_MXSERVER}) ? $ENV{XAS_MXSERVER} : 'mq.example.com';
    $self->{mxport}   = defined($ENV{XAS_MXPORT}) ? $ENV{XAS_MXPORT} : '25';

    $self->{path}    = $ENV{'PATH'};
    $self->{domain}  = defined($ENV{XAS_DOMAIN}) ? $ENV{XAS_DOMAIN} : hostdomain();

    if ($^O eq "aix") {

        $self->{root} = Dir(defined($ENV{XAS_ROOT}) ? $ENV{XAS_ROOT} : '/opt/xas');
        $self->{host} = defined($ENV{XAS_HOSTNAME}) ? $ENV{XAS_HOSTNAME} : `hostname -s`;
        chomp($self->{host});

        $self->{username} = getpwuid($<);

    } elsif ($^O eq "linux"){

        $self->{root} = Dir(defined($ENV{XAS_ROOT}) ? $ENV{XAS_ROOT} : '/opt/xas');
        $self->{host} = defined($ENV{XAS_HOSTNAME}) ? $ENV{XAS_HOSTNAME} : `hostname -s`;
        chomp($self->{host});

        $self->{username} = getpwuid($<);

    } elsif ($^O eq "MSWin32") {

        require Win32;

        $self->{root} = Dir(defined($ENV{XAS_ROOT}) ? $ENV{XAS_ROOT} : "D:\\xas");
        $self->{host} = defined($ENV{XAS_HOSTNAME}) ? $ENV{XAS_HOSTNAME} : Win32::NodeName();

        $self->{username} = Win32::LoginName();

    } else {

        $self->throw_msg(
            'xas.system.environment.unknownos',
            'unknownos', 
            $^O
        );

    }

    # build some common paths

    $self->{etc}   = Dir(defined($ENV{'XAS_ETC'})   ? $ENV{'XAS_ETC'}   : [$self->{root}, 'etc']);
    $self->{sbin}  = Dir(defined($ENV{'XAS_SBIN'})  ? $ENV{'XAS_SBIN'}  : [$self->{root}, 'sbin']);
    $self->{tmp}   = Dir(defined($ENV{'XAS_TMP'})   ? $ENV{'XAS_TMP'}   : [$self->{root}, 'tmp']);
    $self->{bin}   = Dir(defined($ENV{'XAS_BIN'})   ? $ENV{'XAS_BIN'}   : [$self->{root}, 'bin']);
    $self->{lib}   = Dir(defined($ENV{'XAS_LIB'})   ? $ENV{'XAS_LIB'}   : [$self->{root}, 'lib']);
    $self->{var}   = Dir(defined($ENV{'XAS_VAR'})   ? $ENV{'XAS_VAR'}   : [$self->{root}, 'var']);
    $self->{log}   = Dir(defined($ENV{'XAS_LOG'})   ? $ENV{'XAS_LOG'}   : [$self->{root}, 'var', 'log']);
    $self->{run}   = Dir(defined($ENV{'XAS_RUN'})   ? $ENV{'XAS_RUN'}   : [$self->{root}, 'var', 'run']);
    $self->{spool} = Dir(defined($ENV{'XAS_SPOOL'}) ? $ENV{'XAS_SPOOL'} : [$self->{root}, 'var', 'spool']);

    # create some common file names

    ($name, $path, $suffix) = fileparse($0, qr{\..*});

    $self->{logfile} = File($self->{log}, $name . '.log');
    $self->{pidfile} = File($self->{run}, $name . '.pid');
    $self->{cfgfile} = File($self->{etc}, $name . '.ini');

    return $self;

}

# ------------------------------------------------------------------------
# Mutators - uses a closure to set/return data items
# ------------------------------------------------------------------------

# ------------------------------------------------------------------------
# make sure that the passed paramemter is a Badger::Filesystem::File object
# ------------------------------------------------------------------------

for my $datum (qw( logfile pidfile cfgfile  )) {

    no strict "refs";                 # to register new methods in package
    no warnings;                      # turn off warnings

    *$datum = sub {
        my ($self, $p) = @_;

        if (defined($p)) {

            my $ref = ref($p);

            if ($ref && $p->isa('Badger::Filesystem::File')) {

                $self->{$datum} = $p;

            } else {

                $self->throw_msg(
                    "xas.system.paths.$datum.invparams",
                    'invparams',
                    "parameter is not a Badger::Filesystem::File object"
                );

            }

        }

        return $self->{$datum};

    }

}

# ------------------------------------------------------------------------
# make sure that the passed paramemter is a Badger::Filesystem::Dir object
# ------------------------------------------------------------------------

for my $datum (qw( root etc sbin tmp var bin lib log run spool )) {

    no strict "refs";                 # to register new methods in package
    no warnings;                      # turn off warnings

    *$datum = sub {
        my ($self, $p) = @_;

        if (defined($p)) {

            my $ref = ref($p);

            if ($ref && $p->isa('Badger::Filesystem::Directory')) {

                $self->{$datum} = $p;

            } else {

                $self->throw_msg(
                    "xas.system.paths.$datum.invparams",
                    'invparams',
                    "parameter is not a Badger::Filesystem::Directory object"
                );

            }

        }

        return $self->{$datum};

    }

}

1;

__END__


=head1 NAME

XAS::System::Environment - The base environment for the XAS environment

=head1 SYNOPSIS

Your program can use this module in the following fashion:

  use XAS::System;

  $xas = XAS::System->module('environment');

  $pidfile = $xas->pidfile;
  $logfile = $xas->logfile;

  printf("The XAS root is %s\n", $xas->root);

=head1 DESCRIPTION

This module describes the base environment for XAS. It will provide a
uniform description of the directory layout for perl programs within the 
XAS environemnt. 

=head1 METHODS

=head2 new

This method will initialize the base module. It parses the environment using
the following variables:

=over 4

=item B<XAS_ROOT>

The root of the directory structure.

=item B<XAS_LOG>

The path for log files.

=item B<XAS_RUN>

The path for pid files.

=item B<XAS_SPOOL>

The base path for spool files.

=item B<XAS_MQSERVER>

The server where a STOMP enabled message queue is located.

=item B<XAS_MQPORT>

The port that server is listening on.

=item B<XAS_MXSERVER>

The server where a SMTP based mail server resides.

=item B<XAS_MXPORT>

The port it is listening on.

=back

On Debian Linux these are defined in the etc/environment script, which is 
created on initial installation.

=head2 logfile

This method will return a pre-generated name for a log file. The name will be 
based on the programs name with a ".log" extension, along with the path to
the XAS log file directory. Or you can store your own self generated log 
file name.

Example

    $logfile = $xas->logfile;
    $xas->logfile("/some/path/mylogfile.log");

=head2 pidfile

This method will return a pre-generated name for a pid file. The name will be 
based on the programs name with a ".pid" extension, along with the path to
the XAS pid file directory. Or you can store your own self generated pid 
file name.

Example

    $pidfile = $xas->pidfile;
    $xas->pidfile("/some/path/myfile.pid");

=head2 cfgfile

This method will return a pre-generated name for a configuration file. The 
name will be based on the programs name with a ".ini" extension, along with 
the path to the XAS configuration file directory. Or you can store your own 
self generated configuration file name.

Example

    $inifile = $xas->cfgfile;
    $xas->cfgfile("/some/path/myfile.cfg");

=head2 mqserver

This method will return the name of the message queue server. Or you can
store a differant name for the server.

Example

    $mqserver = $xas->mqserver;
    $xas->mqserver('mq.example.com');

=head2 mqport

This method will return the port for the message queue server, or you store
a differant port number for that server.

Example

    $mqport = $xas->mqport;
    $xas->mqport('61613');

=head2 mxserver

This method will return the name of the mail server. Or you can
store a differant name for the server.

Example

    $mxserver = $xas->mxserver;
    $xas->mxserver('mail.example.com');

=head2 mxport

This method will return the port for the mail server, or you store
a differant port number for that server.

Example

    $mxport = $xas->mxport;
    $xas->mxport('25');

=head1 ACCESSORS

=head2 path

This accessor returns the currently defined path for this program.

=head2 root

This accessor returns the root directory of the XAS environment.

=head2 bin

This accessor returns the bin directory of the XAS environment. The bin
directory is used to place executable commands.

=head2 sbin

This accessor returns the sbin directory of the XAS environment. The sbin
directory is used to place system level commands.

=head2 log

This accessor returns the log directory of the XAS environment. 

=head2 run

This accessor returns the run directory of the XAS environment. The run
directory is used to place pid files and other such files.

=head2 etc

This accessor returns the etc directory of the XAS environment. 
Application configuration files should go into this directory.

=head2 lib

This accessor returns the lib directory of the XAS environemnt. This
directory is used to store supporting file for the enviroment.

=head2 spool

This accessor returns the spool directory of the XAS environemnt. This
directory is used to store spool files generated within the environment.

=head2 tmp

This accessor returns the tmp directory of the XAS environment. This
directory is used to store temporary files. 

=head2 var

This accessor returns the var directory of the XAS environment. 

=head2 host

This accessor returns the local hostname. 

=head2 domain

This access returns the domain name of the local host.

=head2 username

This accessor returns the effective username of the current process.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
