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
        -logger => $self->logger
    );

    $collector = XAS::Collector::Factory->load(
        -connector => 'connector',
        -logger    => 'logger',
        -configs   => $configs
    );

    $connection = XAS::Collector::Connector->new(
        -host             => $hostname,
        -port             => $port,
        -retry_reconnect  => TRUE,
        -enable_keepalive => TRUE,
        -alias            => 'connector',
        -logger           => 'logger',
        -login            => 'guest',
        -passcode         => 'guest',
        -queues           => $collector->queues,
        -types            => $collector->types,
    );

    $self->log('info', 'Starting up');

    $poe_kernel->run();

    $self->log('info', 'Shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Base::Collector - This module will process alerts

=head1 SYNOPSIS

 use XAS::Apps::Base::Collector;

 my $app = XAS::Apps::Base::Collector->new(
     -throws => 'xas-collector',
     -options => [
         { 'host=s', '' },
         { 'port=s', '' },
         { 'configs=s' , ''}
     ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will process alerts from the message queue. It inherits from
L<XAS::Lib::App::Daemon::POE|XAS::Lib::App::Daemon::POE>.

=head1 CONFIGURATION

=head2 -throws

This sets the default facility for exceptions.

=head2 -options

This provides three additional options. There format is what can be supplied to
L<Getopt::Long>. The defaults are the supplied values. Those values be can 
overridden on the command line.

=over 4

=item B<'host=s'>

This is the host that the message queue is on.

=item B<'port=s'>

This is the port that it listens on.

=item B<'configs=s'>

This is a configuration file that lists all of the collector processes. The
configuration file has the following format:

    [collector: alert]
    alias = alert
    queue = /queue/alert
    packet-type = xas-alert
    module = XAS::Collector::Alert

This uses the standard .ini format. The entries mean the following:

    [controller: xxxx] - The beginning of the stanza.
    alias              - The alias for this POE session.
    queue              - The message queue to listen on, defaults to '/queue/xas'.
    packet-type        - The message type expected.
    module             - The module that handles that message type.

=back

=head1 SEE ALSO

=over 4

=item sbin/xas-collector.pl

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
