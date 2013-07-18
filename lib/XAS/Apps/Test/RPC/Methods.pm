package XAS::Apps::Test::RPC::Methods;

our $VERSION = '0.02';

use POE;
use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::RPC::JSON::Server',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub echo {
    my ($kernel, $self, $params, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $response = '';

    if (defined($params->{message})) {

        $response = $params->{message};

    }

    $kernel->yield('process_response', $response, $ctx);

}

sub list {
    my ($kernel, $self, $params, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $response = 'echo, list, status';

    $kernel->yield('process_response', $response, $ctx);

}

sub status {
    my ($kernel, $self, $params, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $response = 'OK';

    $kernel->yield('process_response', $response, $ctx);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub initialize {
    my ($self, $kernel, $session) = @_;

    $kernel->state('echo', $self);
    $kernel->state('list', $self);
    $kernel->state('status', $self);

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{methods} = Set::Light->new(qw/echo list status/);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Apps::Test::RPC::Methods - This module provides method to an 'rpc' server

=head1 SYNOPSIS

 use XAS::Apps::Test::RPC::Methods;

 my $app = XAS::Apps::Test::RPC::Methods->new(
     -throws => 'something',
     -options => [
         { 'port=s',    '9507' },
         { 'address=s', 'localhost' },
     ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will provide an 'echo', 'list' and 'status' methods to the rpc server.

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

=item sbin/rpc-server.pl

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
