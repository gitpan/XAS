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
    use File::Basename;
    use File::Spec::Functions qw( catfile catdir rel2abs );

    sub ACTION_install {
        my $self = shift;
        my $base = $self->{properties}{install_base};

        print "\nInstalling XAS to $base...\n";

        my $ret  = $self->SUPER::ACTION_install( @_ );

        $self->dispatch('post_install');

        return $ret;

    }

    sub ACTION_post_install {
        my $self = shift;

        my $base  = $self->{properties}{install_base};

        # create xas owner/group 

        system('addgroup --system xas');
        system("adduser --system --ingroup xas --home $base xas");

        # create some directories

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

        # set ownership/permissions on the files/directories

        system("chown -R xas.xas $base");
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

    sub process_profiled_files {
        my $self = shift;

        my $base = $self->{properties}{install_base};
        my $dir = catfile('blib', 'profiled');
        my $file = catfile('blib', 'profiled', 'xas.sh');

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
            $fh->print(". $base/etc/environment\n");
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

    sub process_etc_files {
        my $self = shift;

        my $file;
        my $result;
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
            $fh->print("name = $dbname\n");
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

        return $self;

    }

    sub process_sbin_files {
        my $self = shift;

        my $file;
        my $result;
        my $files = $self->find_sbin_files;
        my $base = $self->{properties}{install_base};

        my $tmp = catfile('blib', 'sbin');
        mkdir $tmp unless (-e $tmp);

        $file = catfile('blib', 'sbin', 'xas-collector');

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
            $fh->print("PROGRAM=\"$base/sbin/xas-collector.pl\"\n");
            $fh->print("\n");
            $fh->print("# Some simple tests\n");
            $fh->print("\n");
            $fh->print("[ -f \$PROGRAM ] || exit 0\n");
            $fh->print("[ -f $base/etc/environment ] || exit 0\n");
            $fh->print("\n");
            $fh->print(". $base/etc/environment\n");
            $fh->print("\n");
            $fh->print("\$PROGRAM \$1 \$2 \$3\n");
            $fh->print("\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'sbin', 'xas-alerts');

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
            $fh->print("PROGRAM=\"$base/sbin/xas-alerts.pl\"\n");
            $fh->print("\n");
            $fh->print("# Some simple tests\n");
            $fh->print("\n");
            $fh->print("[ -f \$PROGRAM ] || exit 0\n");
            $fh->print("[ -f $base/etc/environment ] || exit 0\n");
            $fh->print("\n");
            $fh->print(". $base/etc/environment\n");
            $fh->print("\n");
            $fh->print("\$PROGRAM \$1 \$2 \$3\n");
            $fh->print("\n");

            undef $fh;

            $self->make_executable($file);

        } else {

            print "Unable to open $file\n"

        }

        $file = catfile('blib', 'sbin', 'xas-spooler');

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
            $fh->print("PROGRAM=\"$base/sbin/xas-spooler.pl\"\n");
            $fh->print("\n");
            $fh->print("# Some simple tests\n");
            $fh->print("\n");
            $fh->print("[ -f \$PROGRAM ] || exit 0\n");
            $fh->print("[ -f $base/etc/environment ] || exit 0\n");
            $fh->print("\n");
            $fh->print(". $base/etc/environment\n");
            $fh->print("\n");
            $fh->print("\$PROGRAM \$1 \$2 \$3\n");
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

    sub process_tmp_files {
        my $self = shift;

        my $tmp = catfile('blib', 'tmp');
        mkdir $tmp unless (-e $tmp);

        return $self;

    }
        
    sub process_spool_files {
        my $self = shift;

        my $tmp = catfile('blib', 'var');
        mkdir $tmp unless (-e $tmp);

        $tmp = catfile('blib', 'var', 'spool');
        mkdir $tmp unless (-e $tmp);

        return $self;

    }

    sub process_run_files {
        my $self = shift;

        my $tmp = catfile('blib', 'var');
        mkdir $tmp unless (-e $tmp);

        $tmp = catfile('blib', 'var', 'run');
        mkdir $tmp unless (-e $tmp);

        return $self;

    }

    sub process_log_files {
        my $self = shift;

        my $tmp = catfile('blib', 'var');
        mkdir $tmp unless (-e $tmp);

        $tmp = catfile('blib', 'var', 'log');
        mkdir $tmp unless (-e $tmp);

        return $self;

    }

    sub process_alert_files {
        my $self = shift;

        my $tmp = catfile('blib', 'var');
        mkdir $tmp unless (-e $tmp);

        $tmp = catfile('blib', 'var', 'spool');
        mkdir $tmp unless (-e $tmp);

        $tmp = catfile('blib', 'var', 'spool', 'alerts');
        mkdir $tmp unless (-e $tmp);

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
        'Badger'                         => 0.06,
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
    },
    create_makefile_pl => 'traditional',
    install_path => {
        profiled => '/etc/profile.d',
        initd    => $initd_dir,
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
$builder->add_build_element('sbin');
$builder->add_build_element('initd');
$builder->add_build_element('etc');

$builder->create_build_script();
