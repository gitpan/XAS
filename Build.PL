use strict;
use warnings;
use Module::Build;
use File::Spec::Functions qw/ catfile catdir rel2abs /;

$| = 1;
my $install_base = catdir(File::Spec->rootdir, 'opt', 'xas');
my @args;
do { $_ =~ /^install_base=(.+)$/ ? $install_base = $1 : push @args, $_ } for (@ARGV);

$install_base = rel2abs($install_base);

my $sbin_dir  = File::Spec->catdir( $install_base, 'sbin' );
my $etc_dir   = File::Spec->catdir( $install_base, 'etc' );
my $initd_dir = File::Spec->catdir( $install_base, 'init.d' );

my $class = Module::Build->subclass(code => <<'EOC');

    use strict;
    use warnings;

    use IO::File;
    use File::Find;
    use Carp qw(croak);
    use File::Basename;
    use FindBin qw($Bin);
    use File::Spec::Functions qw( catfile catdir rel2abs );
    use Data::Dumper;

    sub ACTION_install {
        my $self = shift;

        my $dest = $self->runtime_params('destdir') || '';
        my $base = catdir($dest, $self->{properties}{install_base});

        print "\nInstalling XAS to $base...\n";

        my $ret = $self->SUPER::ACTION_install( @_ );

        # create some additional directories

        my $tmp = catfile($base, 'tmp');
        mkdir $tmp unless (-e $tmp);

        my $var = catfile($base, 'var');
        mkdir $var unless (-e $var);

        my $spool = catfile($base, 'var', 'spool');
        mkdir $spool unless (-e $spool);

        my $alerts = catfile($base, 'var', 'spool', 'alerts');
        mkdir $alerts unless (-e $alerts);

        my $log = catfile($base, 'var', 'log');
        mkdir $log unless (-e $log);

        my $run = catfile($base, 'var', 'run');
        mkdir $run unless (-e $run);

        return $ret;

    }

    sub ACTION_post_install {
        my $self = shift;

        my $base  = $self->{properties}{install_base};

        # create xas owner/group 

        unless (getpwnam('xas')) {

            system('addgroup --system xas');
            system("adduser --system --ingroup xas --home $base xas");

        }

        # set ownership/permissions on the files/directories

        my $tmp = catfile($base, 'tmp');
        system("chown -R xas.xas $tmp");

        my $bin = catfile($base, 'bin');
        system("chown -R xas.xas $bin");

        my $sbin = catfile($base, 'sbin');
        system("chown -R xas.xas $sbin");

        my $lib = catfile($base, 'lib');
        system("chown -R xas.xas $lib");

        my $var = catfile($base, 'var');
        system("chown -R xas.xas $var");

        my $alerts = catfile($base, 'var', 'spool', 'alerts');
        system("chmod 0777 $alerts");

        return $self;

    }

    sub ACTION_fakeinstall {
        my $self = shift;
        my $base = $self->{properties}{install_base};

        print "\nInstalling XAS to $base...\n";
        my $ret  = $self->SUPER::ACTION_fakeinstall( @_ );

        return $ret;

    }

    sub ACTION_debian_postinst {
        my $self = shift;

        my $base  = $self->{properties}{install_base};
        my $file = catfile('debian', 'postinst');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#!/usr/bin/perl\n");
            $fh->print("#\n");
            $fh->print("# File: postinst\n");
            $fh->print("# Date: 28-Jun-2012\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("#\n");
            $fh->print("# This a postinst file for the debian package manager.\n");
            $fh->print("# It creates the xas user and group, along with setting file permissions.\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print("use strict;\n");
            $fh->print("use warnings;\n");
            $fh->print("use File::Spec::Functions qw( catfile catdir rel2abs );\n");
            $fh->print("\n");
            $fh->print("# create xas owner/group \n");
            $fh->print("\n");
            $fh->print("unless (getpwnam('xas')) {\n");
            $fh->print("\n");
            $fh->print("    system('addgroup --system xas');\n");
            $fh->print("    system(\"adduser --system --ingroup xas --home $base xas\");\n");
            $fh->print("\n");
            $fh->print("}\n");
            $fh->print("\n");
            $fh->print("# set ownership/permissions on the files/directories\n");
            $fh->print("\n");
            $fh->print("my \$tmp = catfile('$base', 'tmp');\n");
            $fh->print("system(\"chown -R xas.xas \$tmp\");\n");
            $fh->print("\n");
            $fh->print("my \$bin = catfile('$base', 'bin');\n");
            $fh->print("system(\"chown -R xas.xas \$bin\");\n");
            $fh->print("\n");
            $fh->print("my \$sbin = catfile('$base', 'sbin');\n");
            $fh->print("system(\"chown -R xas.xas \$sbin\");\n");
            $fh->print("\n");
            $fh->print("my \$lib = catfile('$base', 'lib');\n");
            $fh->print("system(\"chown -R xas.xas \$lib\");\n");
            $fh->print("\n");
            $fh->print("my \$var = catfile('$base', 'var');\n");
            $fh->print("system(\"chown -R xas.xas \$var\");\n");
            $fh->print("\n");
            $fh->print("my \$etc = catfile('$base', 'etc');\n");
            $fh->print("system(\"chown -R xas.xas \$etc\");\n");
            $fh->print("\n");
            $fh->print("my \$alerts = catfile('$base', 'var', 'spool', 'alerts');\n");
            $fh->print("system(\"chmod 0777 \$alerts\");\n");
            $fh->print("\n");
            $fh->print("exit 0\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }


        return $self;

    }

    sub process_script_files {
        my $self = shift;

        $self->SUPER::process_script_files(@_);

        my $file;
        my $program;
        my $base = $self->{properties}{install_base};
        my $env  = catfile($base, 'etc', 'environment');

        $file = catfile('blib', 'script', 'xas-supctl');
        $program = catfile($base, 'bin', 'xas-supctl.pl');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#!/bin/sh\n");
            $fh->print("#\n");
            $fh->print("# File: xas-supctl\n");
            $fh->print("# Date: 08-Jul-2013\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("#\n");
            $fh->print("# This procedure will wrap the xas-supctl command with the proper environment.\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print("PROGRAM=\"$program\"\n");
            $fh->print("\n");
            $fh->print("# Some simple tests\n");
            $fh->print("\n");
            $fh->print("[ -f \$PROGRAM ] || exit 0\n");
            $fh->print("[ -f $env ] || exit 0\n");
            $fh->print("\n");
            $fh->print(". $env\n");
            $fh->print("\n");
            $fh->print("\$PROGRAM \$*\n");
            $fh->print("\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

    }

    sub process_profiled_files {
        my $self = shift;

        my $base = $self->{properties}{install_base};
        my $dir  = catfile('blib', 'profiled');
        my $file = catfile('blib', 'profiled', 'xas.sh');
        my $env  = catfile($base, 'etc', 'environment');

        mkdir $dir unless (-e $dir);

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#\n");
            $fh->print("# File: xas.sh\n");
            $fh->print("# Date: 19-Jan-2012\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("#\n");
            $fh->print("# This file defines the environment varaibles for the XAS environment.\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print(". $env\n");
            $fh->print("\n");
            $fh->print("export PATH=\"\$PATH:\$XAS_ROOT/bin:\$XAS_ROOT/sbin\"\n");
            $fh->print("export MANPATH=\"\$MANATH:\$XAS_ROOT/man\"\n");
            $fh->print("\n");

            undef $fh;
            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

        return $self;

    }

    sub process_logd_files {
        my $self = shift;

        my $base   = $self->{properties}{install_base};
        my $dir    = catfile('blib', 'logd');
        my $file   = catfile('blib', 'logd', 'xas');
        my $log    = catdir($base, 'var', 'log');
        my $bin    = catdir($base, 'bin');
        my $supctl = catfile($bin, 'xas-supctl');

        my $alerts    = catfile($log, 'xas-alerts.log');
        my $spooler   = catfile($log, 'xas-spooler.log');
        my $controler = catfile($log, 'xas-collector.log');

        mkdir $dir unless (-e $dir);

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#\n");
            $fh->print("# File: xas\n");
            $fh->print("# Date: 01-Jul-2013\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("#\n");
            $fh->print("# Control file for log rotation\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print("$controler {\n");
            $fh->print("    prerotate\n");
            $fh->print("        $supctl --stop xas-collector\n");
            $fh->print("    endscript\n");
            $fh->print("    rotate 5\n");
            $fh->print("    missingok\n");
            $fh->print("    notifempty\n");
            $fh->print("    sharedscripts\n");
            $fh->print("    create 0664 xas xas\n");
            $fh->print("    postrotate\n");
            $fh->print("        $supctl --start xas-collector\n");
            $fh->print("    endscript\n");
            $fh->print("}\n");
            $fh->print("\n");
            $fh->print("$spooler {\n");
            $fh->print("    prerotate\n");
            $fh->print("        $supctl --stop xas-spooler\n");
            $fh->print("    endscript\n");
            $fh->print("    rotate 5\n");
            $fh->print("    missingok\n");
            $fh->print("    notifempty\n");
            $fh->print("    sharedscripts\n");
            $fh->print("    create 0664 xas xas\n");
            $fh->print("    postrotate\n");
            $fh->print("        $supctl --start xas-spooler\n");
            $fh->print("    endscript\n");
            $fh->print("}\n");
            $fh->print("\n");
            $fh->print("$alerts {\n");
            $fh->print("    prerotate\n");
            $fh->print("        $supctl --stop xas-alerts\n");
            $fh->print("    endscript\n");
            $fh->print("    rotate 5\n");
            $fh->print("    missingok\n");
            $fh->print("    notifempty\n");
            $fh->print("    sharedscripts\n");
            $fh->print("    create 0664 xas xas\n");
            $fh->print("    postrotate\n");
            $fh->print("        $supctl --start xas-alerts\n");
            $fh->print("    endscript\n");
            $fh->print("}\n");
            $fh->print("\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

        return $self;

    }

    sub process_etc_files {
        my $self = shift;

        my $file;
        my $result;
        my $program;
        my $base = $self->{properties}{install_base};
        my $dir = catfile('blib', 'etc');

        my $mqserver = $self->notes('mqserver');
        my $mqport   = $self->notes('mqport');
        my $mxserver = $self->notes('mxserver');
        my $mxport   = $self->notes('mxport');
        my $host     = $self->notes('host');
        my $domain   = $self->notes('domain');

        my $files = $self->find_etc_files;

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        mkdir $dir unless (-e $dir);
        $file = catfile('blib', 'etc', 'environment');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#\n");
            $fh->print("# File: evnironment\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("# Date: 17-Jan-2012\n");
            $fh->print("#\n");
            $fh->print("# Configure the environment for XAS\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print("export XAS_ROOT=\"$base\"\n");
            $fh->print("export XAS_LOG=\"\$XAS_ROOT/var/log\"\n");
            $fh->print("export XAS_RUN=\"\$XAS_ROOT/var/run\"\n");
            $fh->print("export XAS_SPOOL=\"\$XAS_ROOT/var/spool\"\n");
            $fh->print("\n");
            $fh->print("export XAS_MQSERVER=\"$mqserver\"\n");
            $fh->print("export XAS_MQPORT=\"$mqport\"\n");
            $fh->print("\n");
            $fh->print("export XAS_MXSERVER=\"$mxserver\"\n");
            $fh->print("export XAS_MXPORT=\"$mxport\"\n");
            $fh->print("\n");
            $fh->print("export XAS_HOSTNAME=\"$host\"\n");
            $fh->print("export XAS_DOMAIN=\"$domain\"\n");
            $fh->print("\n");

            if (defined($ENV{PERL5LIB})) {

                $fh->print("export PERL5LIB=\"\$PERL5LIB:\$XAS_ROOT/lib/perl5\"\n");

            } else {

                $fh->print("export PERL5LIB=\"\$XAS_ROOT/lib/perl5\"\n");

            }

            $fh->print("\n");

            undef $fh;

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'etc', 'database.ini');

        my $dbname = $self->notes('dbname');
        my $dbuser = $self->notes('dbuser');
        my $dbpass = $self->notes('dbpass');
        my $dbdsn  = $self->notes('dbdsn');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print(";\n");
            $fh->print("; File: database.ini\n");
            $fh->print("; By  : Kevin Esteb\n");
            $fh->print("; Date: 12-Mar-2012\n");
            $fh->print(";\n");
            $fh->print("; Database Configuration for the XAS environment\n");
            $fh->print(";\n");
            $fh->print("\n");
            $fh->print("[database]\n");
            $fh->print("dbname = $dbname\n");
            $fh->print("dsn = $dbdsn\n");
            $fh->print("user = $dbuser\n");
            $fh->print("password = $dbpass\n");
            $fh->print("\n");

            undef $fh;

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'etc', 'xas-collector.ini');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print(";\n");
            $fh->print("; File: xas-collector.ini\n");
            $fh->print("; By  : Kevin Esteb\n");
            $fh->print("; Date: 15-Aug-2012\n");
            $fh->print(";\n");
            $fh->print("; Configuration file for xas/sbin/xas-collector.pl\n");
            $fh->print(";\n");
            $fh->print("\n");
            $fh->print("[collector: alert]\n");
            $fh->print("alias = alert\n");
            $fh->print("packet-type = xas-alert\n");
            $fh->print("module = XAS::Collector::Alert\n");
            $fh->print("\n");

            undef $fh;

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'etc', 'xas-spooler.ini');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print(";\n");
            $fh->print("; File: xas-spooler.ini\n");
            $fh->print("; By  : Kevin Esteb\n");
            $fh->print("; Date: 15-Aug-2012\n");
            $fh->print(";\n");
            $fh->print("; Configuration file for xas/sbin/xas-spooler.pl\n");
            $fh->print(";\n");
            $fh->print("\n");
            $fh->print("[spooler: alert]\n");
            $fh->print("alias = alerts\n");
            $fh->print("directory = alerts\n");
            $fh->print("packet-type = xas-alert\n");
            $fh->print("\n");

            undef $fh;

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'etc', 'xas-supervisor.ini');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print(";\n");
            $fh->print("; File: xas-supervisor.ini\n");
            $fh->print("; By  : Kevin Esteb\n");
            $fh->print("; Date: 08-Jul-2013\n");
            $fh->print(";\n");
            $fh->print("; Configuration file for xas/sbin/xas-supervisor.pl\n");
            $fh->print(";\n");
            $fh->print("\n");

            $program = catfile($base, 'sbin', 'xas-spooler.pl');

            $fh->print("[program: xas-spooler]\n");
            $fh->print("command = $program\n");
            $fh->print("name = xas-spooler\n");
            $fh->print("user = xas\n");
            $fh->print("group = xas\n");
            $fh->print("umask = 0002\n");
            $fh->print("\n");

            $program = catfile($base, 'sbin', 'xas-collector.pl');

            $fh->print("[program: xas-collector]\n");
            $fh->print("command = $program\n");
            $fh->print("name = xas-collector\n");
            $fh->print("user = xas\n");
            $fh->print("group = xas\n");
            $fh->print("umask = 0002\n");
            $fh->print("\n");

            $program = catfile($base, 'sbin', 'xas-alerts.pl');

            $fh->print("[program: xas-alerts]\n");
            $fh->print("command = $program\n");
            $fh->print("name = xas-alerts\n");
            $fh->print("user = xas\n");
            $fh->print("group = xas\n");
            $fh->print("umask = 0002\n");
            $fh->print("\n");

            undef $fh;

        } else {

            print "Unable to open $file\n"

        }

        return $self;

    }

    sub process_sbin_files {
        my $self = shift;

        my $file;
        my $result;
        my $program;

        my $files = $self->find_sbin_files;
        my $base  = $self->{properties}{install_base};
        my $etc   = catdir($base, 'etc');
        my $env   = catfile($etc, 'environment');

        my $tmp = catfile('blib', 'sbin');
        mkdir $tmp unless (-e $tmp);

        $file = catfile('blib', 'sbin', 'xas-collector');
        $program = catfile($base, 'sbin', 'xas-collector.pl');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#!/bin/sh\n");
            $fh->print("#\n");
            $fh->print("# File: xas-collector\n");
            $fh->print("# Date: 12-Mar-2012\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("#\n");
            $fh->print("# This procedure will wrap the xas-collector command with the proper environment.\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print("PROGRAM=\"$program\"\n");
            $fh->print("\n");
            $fh->print("# Some simple tests\n");
            $fh->print("\n");
            $fh->print("[ -f \$PROGRAM ] || exit 0\n");
            $fh->print("[ -f $env ] || exit 0\n");
            $fh->print("\n");
            $fh->print(". $env\n");
            $fh->print("\n");
            $fh->print("\$PROGRAM \$*\n");
            $fh->print("\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'sbin', 'xas-alerts');
        $program = catfile($base, 'sbin', 'xas-alerts.pl');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#!/bin/sh\n");
            $fh->print("#\n");
            $fh->print("# File: xas-alerts\n");
            $fh->print("# Date: 12-Mar-2012\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("#\n");
            $fh->print("# This procedure will wrap the xas-alerts command with the proper environment.\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print("PROGRAM=\"$program\"\n");
            $fh->print("\n");
            $fh->print("# Some simple tests\n");
            $fh->print("\n");
            $fh->print("[ -f \$PROGRAM ] || exit 0\n");
            $fh->print("[ -f $env ] || exit 0\n");
            $fh->print("\n");
            $fh->print(". $env\n");
            $fh->print("\n");
            $fh->print("\$PROGRAM \$*\n");
            $fh->print("\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'sbin', 'xas-spooler');
        $program = catfile($base, 'sbin', 'xas-spooler.pl');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#!/bin/sh\n");
            $fh->print("#\n");
            $fh->print("# File: xas-spooler\n");
            $fh->print("# Date: 13-Feb-2012\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("#\n");
            $fh->print("# This procedure will wrap the xas-spooler command with the proper environment.\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print("PROGRAM=\"$program\"\n");
            $fh->print("\n");
            $fh->print("# Some simple tests\n");
            $fh->print("\n");
            $fh->print("[ -f \$PROGRAM ] || exit 0\n");
            $fh->print("[ -f $env ] || exit 0\n");
            $fh->print("\n");
            $fh->print(". $env\n");
            $fh->print("\n");
            $fh->print("\$PROGRAM \$*\n");
            $fh->print("\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'sbin', 'xas-supervisor');
        $program = catfile($base, 'sbin', 'xas-supervisor.pl');

        if (my $fh = IO::File->new("> $file")) {

            $fh->print("#!/bin/sh\n");
            $fh->print("#\n");
            $fh->print("# File: xas-supervisor\n");
            $fh->print("# Date: 07-Jul-2013\n");
            $fh->print("# By  : Kevin Esteb\n");
            $fh->print("#\n");
            $fh->print("# This procedure will wrap the xas-supervisor command with the proper environment.\n");
            $fh->print("#\n");
            $fh->print("\n");
            $fh->print("PROGRAM=\"$program\"\n");
            $fh->print("\n");
            $fh->print("# Some simple tests\n");
            $fh->print("\n");
            $fh->print("[ -f \$PROGRAM ] || exit 0\n");
            $fh->print("[ -f $env ] || exit 0\n");
            $fh->print("\n");
            $fh->print(". $env\n");
            $fh->print("\n");
            $fh->print("\$PROGRAM \$*\n");
            $fh->print("\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $self->make_executable($from);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_initd_files {
        my $self = shift;

        my $result;
        my $files = $self->find_initd_files;

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $self->make_executable($from);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub find_etc_files { shift->find_all_files_no_svn('etc'); }
    sub find_sbin_files { shift->find_all_files_no_svn('sbin'); }
    sub find_initd_files { shift->find_all_files_no_svn('initd'); }

    sub find_all_files_no_svn {
        my ($self, $dir) = @_;

        my $sub = sub {
            return 1 if ($File::Find::dir !~ /SVN/i and -f $File::Find::name);
        };

        return { map {$_, $_} @{ $self->rscan_dir($dir, $sub) } };

    }

EOC

my $builder = $class->new(
    module_name       => 'XAS',
    license           => 'perl',
    dist_author       => 'Kevin L. Esteb <kevin@kesteb.us>',
    dist_version_from => 'lib/XAS.pm',
    install_base      => $install_base,
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Badger'                         => 0.09,
        'POE'                            => 1.289,
        'DBIx::Class'                    => 0.08121,
        'DBIx::Class::Schema::Config'    => 0.0,
        'DBIx::Class::OptimisticLocking' => 0.0,
        'DateTime'                       => 0.55,
        'DateTime::TimeZone'             => 1.16,
        'DateTime::Format::Strptime'     => 0.0,
        'DateTime::Format::MySQL'        => 0.0,
        'DateTime::Format::Pg'           => 0.0,
        'Config::Any'                    => 0.0,
        'Config::Tiny'                   => 0.0,
        'MIME::Lite'                     => 0.0,
        'Params::Validate'               => 0.95,
        'LockFile::Simple'               => 0.207,
        'Try::Tiny'                      => 0.04,
        'Hash::Merge'                    => 0.0,
        'Gearman::XS'                    => 0.11,
        'Text::Autoformat'               => 0.0,
        'Pod::POM'                       => 0.0,
        'Data::Hexdumper'                => 0.0,
        'Set::Light'                     => 0.0,
    },
    install_path => {
        profiled => '/etc/profile.d',
        logd     => '/etc/logrotate.d',
        initd    => '/etc/init.d',
        sbin     => $sbin_dir,
        etc      => $etc_dir,
    },
);

$builder->notes('mqserver' => $builder->prompt('Enter your STOMP MQ Server', 'mq.example.com'));
$builder->notes('mqport'   => $builder->prompt('Enter the STOMP MQ Port', '61613'));
$builder->notes('mxserver' => $builder->prompt('Enter your Mail Server', 'mail.example.com'));
$builder->notes('mxport'   => $builder->prompt('Enter the Mail server port', '25'));
$builder->notes('host'     => $builder->prompt('Enter this hosts name', 'localhost'));
$builder->notes('domain'   => $builder->prompt('Enter this hosts domain', 'example.com'));

$builder->notes('dbname' => $builder->prompt('Enter the database name', 'XAS'));
$builder->notes('dbuser' => $builder->prompt('Enter the database user', 'xas'));
$builder->notes('dbpass' => $builder->prompt('Enter the database users password', 'password'));
$builder->notes('dbdsn'  => $builder->prompt('Enter the database DSN', 'Pg'));

$builder->add_build_element('profiled');
$builder->add_build_element('initd');
$builder->add_build_element('logd');
$builder->add_build_element('sbin');
$builder->add_build_element('etc');

$builder->create_build_script();
