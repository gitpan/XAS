package XAS::Apps::Test::Echo::Client;

our $VERSION = '0.01';

use Try::Tiny;
use XAS::Lib::Net::Client;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::App',
  accessors => 'handle'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    $self->{handle} = XAS::Lib::Net::Client->new(
        -port => $self->port,
        -host => $self->host,
    );

}

sub do_echo {
    my $self = shift;

    my $message;

    $self->handle->connect();
    $self->handle->put($self->send);

    $message = $self->handle->get();
    $self->handle->disconnect();

    $self->log->info(sprintf("echo = %s", $message));

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log->debug('Starting main section');

    $self->do_echo();

    $self->log->debug('Ending main section');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Test::Echo::Client - This module will send data to the echo server

=head1 SYNOPSIS

 use XAS::Apps::Test::Echo::Client;

 my $app = XAS::Apps::Test::Echo::Client->new(;
    -throws  => 'pg_remove_data',
    -options => [
        {'port=s', '9505'},
        {'host=s', 'localhost'},
        {'send=s', ''}
    ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will send a message to the echo server. This message should be
'echoed' back.

=head1 CONFIGURATION

The following parameters are used to configure the module.

=head2 -options

Defines the command line options for this module. 

=over 4

=item B<'host=s'>

The host the echo server resides on.

=item B<'port=s'>

The port it is listening on.

=item B<'send=s'>

The text to be "echoed" back.

=back

=head1 SEE ALSO

 bin/echo-client.pl

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
