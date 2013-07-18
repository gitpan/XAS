package XAS::Supervisor::Factory;

our $VERSION = '0.02';

use Config::IniFiles;
use Params::Validate ':all';
use XAS::Supervisor::Process;

use XAS::Class
  version   => $VERSION,
  base      => 'Badger::Prototype XAS::Base',
  utils     => 'trim',
  mixin     => 'XAS::Lib::Mixin::Env',
  constants => ':supervisor TRUE FALSE',
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub load {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    my %p = validate(@_, {
        -cfgfile    => { isa => 'Badger::Filesystem::File' },
        -supervisor => { optional => 1, default => 'supervisor' },
    });

    my $cfg;
    my @sections;
    my @processes;
    my $env = env_dump();
    my $ex = 'xas.supervisor.factory.load';

    if ($cfg = Config::IniFiles->new(-file => $p{'-cfgfile'}->path)) {

        @sections = $cfg->Sections;

        foreach my $section (@sections) {

            next if ($section !~ /^program:.*/);

            my ($name) = $section =~ /^program:(.*)/;
            $name = trim($name);

            my $process = XAS::Supervisor::Process->new(
                -alias           => $name,
                -command         => $cfg->val($section, 'command', ''),
                -user            => $cfg->val($section, 'user', 'xas'),
                -group           => $cfg->val($section, 'group', 'xas'),
                -directory       => $cfg->val($section, 'directory', "/"),
                -environment     => $cfg->val($section, 'environment', $env),
                -umask           => $cfg->val($section, 'umask', '0022'),
                -exit_codes      => $cfg->val($section, 'exit-codes', '0,1'),
                -priority        => $cfg->val($section, 'priority', '0'),
                -auto_start      => $cfg->val($section, 'auto-start', TRUE),
                -auto_restart    => $cfg->val($section, 'auto-restart', TRUE),
                -stop_signal     => $cfg->val($section, 'stop-signal', 'TERM'),
                -stop_retries    => $cfg->val($section, 'stop-retries', '5'),
                -stop_wait_secs  => $cfg->val($section, 'stop-wait-secs', '10'),
                -start_retries   => $cfg->val($section, 'start-retries', '5'),
                -start_wait_secs => $cfg->val($section, 'start-wait-secs', '10'),
                -reload_signal   => $cfg->val($section, 'reload-signal', 'HUP'),
                -supervisor      => $p{'-supervisor'},
                -xdebug          => $self->xdebug,
            );

            push(@processes, $process);

        }

    } else {

        $ex .= '.badini';
        $self->throw_msg($ex, 'badini', $self->config);

    }

    return \@processes;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Supervisor::Factory - factory method to load processes

=head1 SYNOPSIS

This module is used to create multiple processes from a configuration file.

 my $ctx;
 my @processes = XAS::Supervisor::Factory->load(
    -cfgfile    => 'supervisor.ini',
    -supervisor => 'supervisor',
 );

 foreach my $process (@processes) {

     $process->startme($ctx);

 }

=head1 DESCRIPTION

This module will take a configuration file and initilize all the managed 
processes defined within. The configuration follows the familiar Win32 .ini 
format. It is based, partially, on the configuration file used by the
Supervisord project. Here is an example:

 ; My configuration file
 ;
 [program:test]
 command = /home/kesteb/outside/Supervisor/trunk/bin/test.sh
 user = kesteb

This is the minimum of items needed to define a managed process. There are many
more available. So what does this minimum show: 

=over 4

o Item names are case sensitve.

o A ";" indicates the start of a comment.

o The section header must be unique and start with "program:".

o It defines the command to be ran.

o It defines a name that will be used to control the process.

o It defines the user context that the command will be ran under.

=back

These configuration items have corresponding parameters in XAS::Supervisor::Process.

=head1 ITEMS

=head2 B<command>

This specifies the command to be ran. This must be supplied. It is directly
related to the -command parameter.

=head2 B<user>

This specifies the user context this command will run under. This must be
supplied. It is directly related to the -user parameter.

=head2 B<directory>

The directory to set as the default before running the command. Defaults to
"/". It is directly related to the -directory parameter.

=head2 B<environment>

The environment variables that are set before running the command. Defaults to
the environment varaibles within the main supervisor's processes context. It 
is directly related to the -environment parameter.

=head2 B<umask>

The umask of the command that is being ran. It defaults to "0022". It is
directly related to the -umask parameter.

=head2 B<exit-codes>

The expected exit codes from the process. It defaults to "0,1" and is an array.
If the processes exit code doesn't match these values. The process will not be
re-started. It is directly related to the -exit_codes parameter.

=head2 B<priority>

The priority that the process will be ran under. It defaults to "0". It is
directly related to the -priotity parameter.

=head2 B<auto-start>

Indicates wither the process should be started when the supervisor starts up. 
Defaults to "1" for true, and where "0" is false. It is directly related to the 
-auto_start parameter.

=head2 B<auto-restart>

Indicates wither to automatically restart the process when it exits. Defaults
to "1" for true and where "0" is false. It is directly related to the -auto_restart 
parameter.

=head2 B<stop-signal>

Indicates which signal to use to stop the process. Defaults to "TERM". It
is directly related to the -stop_signal parameter.

=head2 B<stop-retries>

Indicates how many times the supervisor should try to stop the process before
sending it a KILL signal. Defaults to "5". I tis directly related to the 
-stop_retries parameter.

=head2 B<stop-wait-secs>

Indicates how many seconds to wait between attempts to stop the process. 
Defaults to "10". It is directly related to the -stop_wait_secs parameter.

=head2 B<start-retries>

Indicates how many start attempts should be done on process. Defaults to "5".
It is directly realted to the -start_retries parameter.

=head2 B<start-wait-secs>

Indicates how many seconds to wait between attempts to start the process.
Defaults to "10". If is directly related to the -start_wait_secs parameter.

=head2 B<reload-signal>

Indicates the signal to use to send a "reload" signal to the process. Defaults
to "HUP". It is directly related to the -reload_signal parameter.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
