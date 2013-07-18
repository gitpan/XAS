package XAS::Apps::Test::Echo::Server;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use XAS::System;
use XAS::Lib::Net::Server;
use XAS::Lib::Daemon::Logger;

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::App::Daemon::POE',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    my ($logger, $server);

    $logger = XAS::Lib::Daemon::Logger->new(
        -alias  => 'logger',
        -logger => $self->logger
    );

    $server = XAS::Lib::Net::Server->new(
        -alias   => 'echo',
        -logger  => 'logger',
        -port    => $self->port,
        -address => $self->address,
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

XAS::Apps::Test::Echo::Server - This module is an 'echo' server

=head1 SYNOPSIS

 use XAS::Apps::Test::Echo::Server;

 my $app = XAS::Apps::Test::Echo::Server->new(
     -throws => 'something',
     -options => [
         { 'port=s',    '' },
         { 'address=s', '' },
     ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will 'echo' received messages back to the sender.

=head1 METHODS

=head2 new

This method will initialize the module and accepts these parameters.

=over 4

=item B<-options>

This specifies three options that may be on the command line. They are

    port    - the port to listen on.
    address - the address to bind too.

=back

=head1 SEE ALSO

=over 4

=item sbin/echo-server.pl

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
