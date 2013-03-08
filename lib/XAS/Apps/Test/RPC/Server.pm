package XAS::Apps::Test::RPC::Server;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::Lib::Daemon::Logger;
use XAS::Apps::Test::RPC::Methods;

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
        -logger => $self->log
    );

    $server = XAS::Apps::Test::RPC::Methods->new(
        -alias   => 'rpc',
        -logger  => 'logger',
        -port    => $self->port,
        -address => $self->address,
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

XAS::Apps::Test::RPC::Server - This module is a 'rpc' server

=head1 SYNOPSIS

 use XAS::Apps::Test::RPC::Server;

 my $app = XAS::Apps::Test::RPC::Server->new(
     -throws => 'something',
     -options => [
         { 'port=s',    '9507' },
         { 'address=s', 'localhost' },
     ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module provides a simple rpc server.

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

 XAS::Daemon::Logger
 XAS::Lib::App::Daemon
 XAS::Lib::Net::Server
 XAS::Lib::App::Daemon::POE
 XAS::Apps::Test::Echo::Client

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
