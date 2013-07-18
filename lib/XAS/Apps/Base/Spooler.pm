package XAS::Apps::Base::Spooler;

use POE;
use Try::Tiny;
use XAS::Spooler::Factory;
use XAS::Spooler::Connector;
use XAS::Lib::Daemon::Logger;

use XAS::Class
  version    => '0.01',
  base       => 'XAS::Lib::App::Daemon::POE',
  constants  => 'TRUE FALSE',
  filesystem => 'File',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    my ($logger, $processor);

    my $port     = ($self->port ne '')    ? $self->port    : $self->env->mqport;
    my $configs  = ($self->configs ne '') ? $self->configs : $self->env->cfgfile;
    my $hostname = ($self->host ne '')    ? $self->host    : $self->env->mqserver;

    $self->log('debug', "port = $port, hostname = $hostname, configs = $configs");

    $logger = XAS::Lib::Daemon::Logger->new(
        -alias  => 'logger',
        -logger => $self->logger
    );

    $processor = XAS::Spooler::Factory->load(
        -connector => 'connector',
        -logger    => 'logger',
        -configs   => File($configs)
    );

    XAS::Spooler::Connector->new(
        -host             => $hostname,
        -port             => $port,
        -retry_reconnect  => TRUE,
        -enable_keepalive => TRUE,
        -hostname         => $self->env->host,
        -login            => 'xas',
        -passcode         => 'xas',
        -alias            => 'connector',
        -processor        => $processor,
        -logger           => 'logger',
        -queues           => $processor->queues,
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

XAS::Apps::Base::Spooler - A spooler for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Base::Spooler;

 my $app = XAS::Apps::Base::Spooler->new(
     -throws => 'xas-spooler',
     -options => [
         { 'host=s'    => 'localhost' },
         { 'port=s'    => '61613' }
         { 'configs=s' => '' },
     ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module starts up several POE sessions to process spool files and 
send them to the message queue. It inherits from
L<XAS::Lib::App::Daemon::POE|XAS::Lib::App::Daemon::POE>. Please see that
module for additional documentation.

=head1 CONFIGURATION

=head2 -throws

This sets the default facility for exceptions.

=head2 -options

This provides three additional options. There format is what can be supplied to
Getopt::Long. The defaults are the supplied values. Those values be can 
overridden on the command line.

=over 4

=item B<'host=s'>

This is the host that the message queue is on.

=item B<'port=s'>

This is the port that it listens on.

=item B<'configs=s'>

This is a configuration file that lists all of the spool directories 
to process. The configuration file has the following format:

    [spooler: alerts]
    alias = alerts
    directory = alerts
    packet-type = xas-alert

This uses the standard .ini format. The entries mean the following:

    [spooler:xxxx] - The start of a new section. Where xxxx can 
                     be anything.
    alias          - The alias for the POE session.
    directory      - The directory to scan, this is relative to
                     the XAS spool directory.
    queue          - The message queue to use, defaults to /queue/xas.
    packet-type    - The packet type of the spool data. This is
                     used by the collector when storing the packet 
                     into the database.

=back

=head1 SEE ALSO

=over 4

=item sbin/xas-spooler.pl

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
