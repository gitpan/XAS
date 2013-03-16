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

sub main {
    my $self = shift;

    my ($collector, $logger, $connection);

    my $port     = ($self->port ne '') ? $self->port : $self->env->mqport;
    my $hostname = ($self->host ne '') ? $self->host : $self->env->mqserver;
    my $configs  = File(($self->configs ne '') ? $self->configs : $self->env->cfgfile);

    $logger = XAS::Lib::Daemon::Logger->new(
        -alias  => 'logger',
        -logger => $self->log
    );

    $collector = XAS::Collector::Factory->load(
        -connector => 'connector',
        -logger    => 'logger',
        -configs   => $configs
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
        Queues          => $collector->queues,
        Types           => $collector->types,
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

All of these options will default to what is defined in L<XAS::System::Environment|XAS::System::Environment>.

=back

=head1 SEE ALSO

 sbin/xas-collector.pl

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
