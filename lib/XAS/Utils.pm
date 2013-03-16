package XAS::Utils;

our $VERSION = '0.03';

use DateTime;
use Try::Tiny;
use XAS::Exception;
use POSIX ':sys_wait_h';
use DateTime::Format::Pg;
use Digest::MD5 'md5_hex';
use Params::Validate ':all';
use DateTime::Format::Strptime;

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Base Badger::Utils',
  constants  => 'HASH ARRAY',
  filesystem => 'Dir File',
  constant => {
      ERRMSG => 'invalid parameters passed from %s at line %s', 
  },
  exports => {
      all => 'db2dt dt2db trim ltrim rtrim daemonize hash_walk keygen load_module bool init_module load_module compress exitcode kill_proc spawn',
      any => 'db2dt dt2db trim ltrim rtrim daemonize hash_walk keygen load_module bool init_module load_module compress exitcode kill_proc spawn',
      tags => {
          dates   => 'db2dt dt2db',
          modules => 'init_module load_module',
          strings => 'trim ltrim rtrim compress',
          process => 'daemonize spawn kill_proc exitcode',
      }
  }
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# recursively walk a HOH
sub hash_walk {

    my %p = validate(@_,
        {
            -hash     => { type => HASHREF }, 
            -keys     => { type => ARRAYREF }, 
            -callback => { type => CODEREF },
        }
    );

    my $hash     = $p{'-hash'};
    my $key_list = $p{'-keys'};
    my $callback = $p{'-callback'};

    while (my ($k, $v) = each %$hash) {

        # Keep track of the hierarchy of keys, in case
        # our callback needs it.

        push(@$key_list, $k);

        if (ref($v) eq 'HASH') {

            # Recurse.

            hash_walk(-hash => $v, -keys => $key_list, -callback => $callback);

        } else {
            # Otherwise, invoke our callback, passing it
            # the current key and value, along with the
            # full parentage of that key.

            $callback->($k, $v, $key_list);

        }

        pop(@$key_list);

    }

}

# Perl trim function to remove whitespace from the start and end of the string
sub trim {
    my $string = shift;

    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    return $string;

}

# Left trim function to remove leading whitespace
sub ltrim {
    my $string = shift;

    $string =~ s/^\s+//;

    return $string;

}

# Right trim function to remove trailing whitespace
sub rtrim {
    my $string = shift;

    $string =~ s/\s+$//;

    return $string;

}

# replace multiple whitspace with a single space
sub compress {
    my $string = shift;

    $string =~ s/\s+/ /gms;

    return $string;

}

sub bool {
    my $item = shift;

    my @truth = qw(yes true 1 0e0);
    return grep {lc($item) eq $_} @truth;

}

sub spawn {

    my %p = validate(@_,
        {
            -command => 1,
            -timeout => { optional => 1, default => 0 },
        }
    );

    local $SIG{ALRM} = sub {
        my $sig_name = shift;
        die "$sig_name";
    };

    my $kid;
    my @output;

    defined( my $pid = open($kid, "-|" ) ) or do {

        my $ex = XAS::Exception->new(
            info => "unable to fork, reason: $!",
            type => 'xas.utils.spawn'
        );

        $ex->throw;

    };

    if ($pid) {

        # parent

        try {

            alarm( $p{'-timeout'} );

            while (<$kid>) {

                chomp;
                push @output, $_;

            }

            alarm(0);

        } catch {

            my $ex = $_;

            alarm(0);

            if ($ex =~ /alrm/i) {

                unless (kill_proc(-signal => 'TERM', -pid => $pid)) {

                    unless (kill_proc(-signal => 'KILL', -pid => $pid)) {

                        my $ex = Badger::Exception->new(
                            type => 'xas.utils.spawn',
                            info => 'unable to kill ' . $pid
                        );

                        $ex->throw;

                    }

                }

            } else {

                die $ex;

            }

        };

    } else {

        # child

        # set the child process to be a group leader, so that
        # kill -9 will kill it and all its descendents

        setpgrp(0, 0);
        exec $p{'-command'};
        exit;

    }

    wantarray ? @output : join( "\n", @output );

}

sub kill_proc {

    my %p = validate(@_,
        {
            -signal => 1,
            -pid    => 1,
        }
    );

    my $time = 10;
    my $status = 0;
    my $pid = $p{'-pid'};
    my $signal = $p{'-signal'};

    kill($signal, $pid);

    do {

        sleep 1;
        $status = waitpid($pid, WNOHANG);
        $time--;

    } while ($time && not $status);

    return $status;

}

sub exitcode {

    my $rc  = $? >> 8;      # return code of command
    my $sig = $? & 127;     # signal it was killed with

    return $rc, $sig;

}

sub daemonize {

    my $child = fork();

    unless (defined($child)) {

        my $ex = XAS::Exception->new(
            type => 'xas.utils.daemonize',
            info => "unable to fork, reason: $!"
        );

        $ex->throw;

    }

    exit(0) if ($child);

    POSIX::setsid();
    chdir('/');
    open(STDIN,  ">/dev/null");
    open(STDOUT, ">/dev/null");
    open(STDERR, ">/dev/null");
    umask(0);

}

sub db2dt {
    my ($p) = shift;

    my $dt;
    my $parser;

    if ($p =~ m/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/) {

        $parser = DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d %H:%M:%S',
            time_zone => 'local',
            on_error => sub {
                my ($obj, $err) = @_;
	            my $ex = XAS::Exception->new(
                    type => 'xas.utils.db2dt',
                    info => $err
                );
                $ex->throw;
            }
        );

        $dt = $parser->parse_datetime($p);

    } else {

        my ($package, $file, $line) = caller;
        my $ex = XAS::Exception->new(
            type => 'xas.utils.db2dt',
            info => sprintf(ERRMSG, $package, $line)
        );

        $ex->throw;

    }

    return $dt;

}

sub dt2db {
    my ($p) = shift;

    my $ft;
    my $parser;

    my $ref = ref($p);

    if ($ref && $p->isa('DateTime')) {

        $parser = DateTime::Format::Strptime->new(
            pattern => '%Y-%m-%d %H:%M:%S',
            time_zone => 'local',
            on_error => sub {
                my ($obj, $err) = @_;
	            my $ex = XAS::Exception->new(
                    type => 'xas.utils.dt2db',
                    info => $err
                );
                $ex->throw;
            }
        );

        $ft = $parser->format_datetime($p);

    } else {

        my ($package, $file, $line) = caller;
        my $ex = XAS::Exception->new(
            type => 'xas.utils.dt2db',
            info => sprintf(ERRMSG, $package, $line)
        );

        $ex->throw;

    }

    return $ft;

}

sub keygen {

    my %p = validate(@_,
        {
            -url    => 1, 
            -params => 1, 
        }
    );

    my $url    = $p{'-url'};
    my $params = $p{'-params'};

    my $hash;
    my $key = $url;
    my $ref = ref($params);

    if ($ref eq HASH) {

        foreach my $k (sort (keys(%$params))) {

            $key .= $k . $params->{$k};

        }

    } elsif ($ref eq ARRAY) {

        my @p = sort {
            (($a->{field} cmp $b->{field}) or
             (($a->{comparison} or '') cmp ($b->{comparison} or '')));
        } @$params;

        foreach my $f (@p) {

            if ($f->{type} eq 'list') {

                $key .= $f->{field} . join(',', sort(@{$f->{value}}));

            } else {

                $key .= $f->{field} . $f->{value};

            }

        }

    } else {

        my ($package, $file, $line) = caller;
        my $ex = XAS::Exception->new(
            type => 'xas.utils.keygen',
            info => sprintf(ERRMSG, $package, $line)
        );

        $ex->throw;

    }

    $key =~ s/\///g;
    $key =~ s/://g;
    $key =~ s/-//g;
    $key =~ s/_//g;
    $key =~ s/,//g;
    $key =~ s/\.//g;

    $hash = md5_hex($key);

    return $hash;

}

sub init_module {
    my ($module, $params) = validate_pos(@_, 1, {optional => 1, type => HASHREF});

    my $obj;
    my @parts;
    my $filename;

    $params = {} unless (defined($params));

    if ($module) {

        @parts = split("::", $module);
        $filename = File(@parts);

        try {

            require $filename . '.pm';
            $module->import();
            $obj = $module->new($params);

        } catch {

            my $x = $_;
            my $ex = Badger::Exception->new(
                type => 'xas.utils.init_module',
                info => $x
            );

            $ex->throw;

        };

    } else {

        my $ex = Badger::Exception->new(
            type => 'xas.utils.init_module',
            info => 'no module was defined'
        );

        $ex->throw;

    }

    return $obj;

}

sub load_module {
    my $module = shift;

    my @parts;
    my $filename;

    if ($module) {

        @parts = split("::", $module);
        $filename = File(@parts);

        try {

            require $filename . '.pm';
            $module->import();

        } catch {

            my $x = $_;
            my $ex = XAS::Exception->new(
                type => 'xas.utils.load_module',
                info => $x
            );

            $ex->throw;

        };

    } else {

        my $ex = XAS::Exception->new(
            type => 'xas.utils.load_module',
            info => 'no module was defined'
        );

        $ex->throw;

    }

}

1;

__END__

=head1 NAME

XAS::Utils - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Base',
   utils   => 'db2dt dt2db'
 ;

 printf("%s\n", dt2db($dt));

=head1 DESCRIPTION

This module provides utility routines that can by loaded into your current 
namespace. 

=head1 METHODS

=head2 db2dt($datestring)

This routine will take a date format of YYYY-MM-DD HH:MM:SS and convert it
into a DateTime object.

=head2 dt2db($datetime)

This routine will take a DateTime object and convert it into the following
string: YYYY-MM-DD HH:MM:SS

=head2 trim($string)

Trim the whitespace from the beginning and end of a string.

=head2 ltrim($string)

Trim the whitespace from the end of a string.

=head2 rtrim($string)

Trim the whitespace from the beginning of a string.

=head2 compress($string)

Reduces multiple whitespace to a single space.

=head2 spawn

Run a cli command with timeout. Returns output from that command.

=over 4

=item B<-command>

The command string to run.

=item B<-timeout>

An optional timeout in seconds. Default is none.

=back

=head2 exitcode

Decodes perls exit code of a cli process. Returns two items.

 Example:

     my @output = spawn(-command => "ls -l");
     my ($rc, $sig) = exitcode();

=head2 daemonize

Become a daemon. This will set the process as a session lead, change to '/',
clear the protection mask and redirect stdin, stdout and stderr to /dev/null.

=head2 hash_walk

This routine will walk a HOH and does a callback on the key/values that are 
found. It takes three named parameters:

=over 4

=item B<-hash>

The hashref of the HOH.

=item B<-keys>

An arrayref of the key levels.

=item B<-callback>

The routine to call with these parameters:

=over 4

=item B<$key>

The current hash key.

=item B<$value>

The value of that key.

=item B<$key_list>

A list of the key depth.

=back

=back

=head2 keygen

This routine takes a set of parameters formated like a ExtJS 4.1 request and
generates a md5 hash value from them.

=over 4

=item B<-url>

A URL.

=item B<-params>

The parameters. 

=back

=head2 init_module

This routine will load and initialize a module. It takes one required parameter
and one optinal parameter.

=over 4

=item B<$module>

The name of the module.

=item B<$options>

A hashref of optional options to use with the module.

=back

=head2 load_module

This routine will load a module. 

=over 4

=item B<$module>

The name of the module.

=back

=head1 SEE ALSO

 Badger::Utils

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
