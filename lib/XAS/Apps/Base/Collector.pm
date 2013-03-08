package XAS::Apps::Base::Collector;

our $VERSION = '0.04';

use POE;
use Try::Tiny;
use XAS::System;
use XAS::Collector::Factory;
use XAS::Lib::Daemon::Logger;
use XAS::Collector::Connector;

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Lib::App::Daemon::POE',
  filesystem => 'File',
  constants  => 'TRUE FALSE'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my ($self, $configs) = @_;

    my $cfg;
    my @types;
    my @queues;
    my @sections;

    if ($cfg = Config::IniFiles->new(-file => $configs->path)) {

        @sections = $cfg->Sections;

        foreach my $section (@sections) {

            next if ($section !~ /^collector:/);

            push(@types, {
                $cfg->val($section, 'packet-type'),
                $cfg->val($section, 'alias')
            });

            push(@queues, $cfg->val($section, 'queue'));

        }

    } else {

        $self->throw($self->message('badini', $configs));

    }

    return \@types, \@queues;

}

sub main {
    my $self = shift;

    my ($collector, $logger, $connection);

    my $port     = ($self->port ne '') ? $self->port : $self->env->mqport;
    my $hostname = ($self->host ne '') ? $self->host : $self->env->mqserver;
    my $configs  = File(($self->configs ne '') ? $self->configs : $self->env->cfgfile);

    my ($types, $queues) = $self->setup($configs);

    $logger = XAS::Lib::Daemon::Logger->new(
        -alias  => 'logger',
        -logger => $self->log
    );

    $connection = XAS::Collector::Connector->spawn(
        RemoteAddress   => $hostname,
        RemotePort      => $port,
        RetryReconnect  => TRUE,
        EnableKeepAlive => TRUE,
        Alias           => 'connector',
        Logger          => 'logger',
        Login           => 'guest',
        Passcode        => 'guest',
        Queues          => $queues,
        Types           => $types
    );

    $collector = XAS::Collector::Factory->load(
        -connector => 'connector',
        -logger    => 'logger',
        -configs   => $configs
    );

    $self->log->info('Starting up');

    $poe_kernel->run();

    $self->log->info('Shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Base::Collector - This module will collect alerts

=head1 SYNOPSIS

 use XAS::Apps::Base::Collector;

 my $app = XAS::Apps::Base::Collector->new(
     -options => [
         { 'host=s', '' },
         { 'port=s', '' },
         { 'configs=s' , ''}
     ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will collect alerts from the message queue. It inherits from
XAS::Lib::App::Daemon::POE.

=head1 METHODS

=head2 new

This method will initialize the module and accepts these parameters.

=over 4

=item B<-options>

This specifies three options that may be on the command line. They are

    port    - the port to use on the host.
    host    - the host the message queue resides on.
    configs - the configuration file to use.

All of these options will default to what is defined in XAS::System::Environment.

=back

=head1 SEE ALSO

 XAS::Daemon::Logger
 XAS::Lib::App::Daemon
 XAS::System::Environment
 XAS::Lib::App::Daemon::POE
 XAS::Monitor::Database::Alert

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
