package XAS::Apps::Test::RPC::Client;

our $VERSION = '0.01';

use Try::Tiny;
use XAS::Lib::RPC::JSON::Client;

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

    $self->{handle} = XAS::Lib::RPC::JSON::Client->new(
        -port => $self->port,
        -host => $self->host,
    );

}

sub do_echo {
    my $self = shift;

    my $response = $self->handle->call(
        -method => 'echo',
        -id     => 'echo',
        -params => {
            message => $self->echo
        }
    );

    $self->log->info(sprintf("echo = %s", $response));

}

sub do_status {
    my $self = shift;

    my $response = $self->handle->call(
        -method => 'status',
        -id     => 'status',
        -params => {}
    );

    $self->log->info(sprintf("status = %s", $response));

}

sub do_list {
    my $self = shift;

    my $response = $self->handle->call(
        -method => 'list',
        -id     => 'list',
        -params => {}
    );

    $self->log->info(sprintf("methods = %s", $response));

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log->debug('Starting main section');

    $self->do_echo()   if ($self->echo);
    $self->do_list()   if ($self->list);
    $self->do_status() if ($self->status);

    $self->log->debug('Ending main section');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Test::RPC::Client - This module will make calls to the RPC server

=head1 SYNOPSIS

 use XAS::Constants 'TRUE FALSE';
 use XAS::Apps::Test::RPC::Client;

 my $app = XAS::Apps::Test::RPC::Client->new(;
    -throws  => 'something',
    -options => [
        {'port=s', '9505'},
        {'host=s', 'localhost'},
        {'list',   FALSE},
        {'status', FALSE},
        {'echo=s', ''}
    ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will make calls to the rpc server.

=head1 CONFIGURATION

The following parameters are used to configure the module.

=head2 -options

Defines the command line options for this module. 

=over 4

=item B<'host=s'>

The host the echo server resides on.

=item B<'port=s'>

The port it is listening on.

=item B<'echo=s'>

The message to be "echoed" back.

=item B<'list'>

This will list the available methods on the rpc server.

=item B<'status'>

This will list the status of the rpc server.

=back

=head1 SEE ALSO

 bin/rpc-client.pl

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
