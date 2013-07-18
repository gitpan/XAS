package XAS::Apps::Base::Supervisor;

our $VERSION = '0.01';

use POE;
use XAS::Lib::Daemon::Logger;
use XAS::Supervisor::Factory;
use XAS::Supervisor::Controller;

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

    my ($logger, $supervisor, $configs);

    $configs = File(($self->cfgfile ne '') ? $self->cfgfile : $self->env->cfgfile);

    $logger = XAS::Lib::Daemon::Logger->new(
        -alias  => 'logger',
        -logger => $self->logger
    );

    $supervisor = XAS::Supervisor::Controller->new(
        -alias     => 'supervisor',
        -logger    => 'logger',
        -port      => $self->port,
        -address   => $self->address,
        -processes => XAS::Supervisor::Factory->load(
            -cfgfile    => $configs,
            -supervisor => 'supervisor'
        )
    );

    $self->log('info', 'starting up');

    $poe_kernel->run();

    $self->log('info', 'shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Base::Supervisor - This module will supervise other processes

=head1 SYNOPSIS

 use XAS::Apps::Base::Supervisor;

 my $app = XAS::Apps::Base::Supervisor->new(
     -throws => 'xas-supervisor',
     -options => [
         { 'address=s', '127.0.0.1' },
         { 'port=s',    '9505' },
         { 'cfgfile=s', ''}
     ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will start other processes and the supervise them. It inherits from
L<XAS::Lib::App::Daemon::POE|XAS::Lib::App::Daemon::POE>.

=head1 CONFIGURATION

=head2 -throws

This sets the default facility for exceptions.

=head2 -options

This provides three additional options. There format is what can be supplied to
L<Getopt::Long>. The defaults are the supplied values. Those values be can 
overridden on the command line.

=over 4

=item B<'address=s'>

This is the address to listen on.

=item B<'port=s'>

This is the port that to listens on.

=item B<'cfgfile=s'>

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

=item  sbin/xas-supervisor.pl

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
