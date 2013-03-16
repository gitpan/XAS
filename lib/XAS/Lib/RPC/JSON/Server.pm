package XAS::Lib::RPC::JSON::Server;

our $VERSION = '0.02';

use POE;
use Try::Tiny;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Net::Server',
  codec     => 'JSON',
  constants => 'HASH ARRAY :jsonrpc',
  messages => {
      'rpc_method'  => "the rpc method \"%s\" is unknown",
      'rpc_version' => "this server supports only json-rpc version 2.0",
      'rpc_format'  => "this json-rpc format is not supported",
      'rpc_batch'   => "the usage of json-rpc batch mode is not supported",
      'rpc_notify'  => "the usage of json-rpc notifications is not supported",
      'nologger'    => 'no Logger defined',
  },
;

my $errors = {
    '-32700' => 'Parse Error',
    '-32600' => 'Invalid Request',
    '-32601' => 'Method not Found',
    '-32602' => 'Invalid Params',
    '-32603' => 'Internal Error',
    '-32099' => 'Server Error',
    '-32001' => 'App Error',
};

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub process {
    my ($self, $message, $wheel) = @_;

    my $result;
    my $packet;
    my $output;
    my $request;
    my @packets;

    $request = decode($message);

    if (ref($request) eq ARRAY) {

        foreach my $r (@$request) {

            try {

                $result = $self->_process_request($r);
                $packet = $self->_rpc_result($r->{id}, $result);

            } catch {

                my $ex = $_;

                $packet = $self->_exception_handler($ex, $r->{id});

            };

            push(@packets, $packet);

        }

        $output = encode(@packets);

    } else {

        try {

            $result = $self->_process_request($request);
            $packet = $self->_rpc_result($request->{id}, $result);

        } catch {

            my $ex = $_;

	        $packet = $self->_exception_handler($ex, $request->{id});

        };

        $output = encode($packet);

    }

    return $output;

}

sub log {
    my ($self, $level, $message) = @_;

    my $logger = $self->logger;

    $poe_kernel->post($logger, $level, $message);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _exception_handler {
    my ($self, $ex, $id) = @_;

    my $packet;
    my $ref = ref($ex);

    if ($ref) {

        if ($ex->isa('XAS::Exception')) {

            my $type = $ex->type;
            my $info = $ex->info;

            if ($type eq ('xas.lib.rpc.json.server.rpc_method')) {

                $packet = $self->_rpc_error($id, RPC_ERR_METHOD, $info);

            } elsif ($type eq ('xas.lib.rpc.json.server.rpc_version')) {

                $packet = $self->_rpc_error($id, RPC_ERR_REQ, $info);

            } elsif ($type eq ('xas.lib.rpc.json.server.rpc_format')) {

                $packet = $self->_rpc_error($id, RPC_ERR_PARSE, $info);

            } elsif ($type eq ('xas.lib.rpc.json.server.rpc_notify')) {

                $packet = $self->_rpc_error($id, RPC_ERR_INTERNAL, $info);

            } else {

                my $msg = $type . ' - ' . $info;
                $packet = $self->_rpc_error($id, RPC_ERR_APP, $msg);

            }

        } else {

            $packet = $self->_rpc_error($id, RPC_ERR_SERVER, "Server error");

        }

    } else {

        my $msg = sprintf("%s", $ex);
        $packet = $self->_rpc_error($id, RPC_ERR_APP, $msg);

    }

    return $packet;

}

sub _process_request {
    my ($self, $request) = @_;

    my $method;
    my $output;

    if (ref($request) ne HASH) {

        $self->throw_msg(
            'xas.lib.rpc.json.server.format', 
            'rpc_format'
        );

    }

    if ($request->{jsonrpc} ne RPC_JSON) {

        $self->throw_msg(
            'xas.lib.rpc.json.server.rpc_version', 
            'rpc_version'
        );

    }

    unless (defined($request->{id})) {

        $self->throw_msg(
            'xas.lib.rpc.json.server.nonotifications', 
            'rpc_nonotify'
        );

    }

    $method = 'do_' . $request->{method};

    if ($self->can($method)) {

        $output = $self->$method($request->{params});

    } else {

        $self->throw_msg(
            'xas.lib.rpc.json.server.rpc_method', 
            'rpc_method', 
            $request->{method}
        );

    }

    return $output;

}

sub _rpc_error {
    my ($self, $id, $code, $message) = @_;

    my $response = {
        jsonrpc => RPC_JSON,
        id      => $id,
        error   => {
            code    => $code,
            message => $errors->{$code},
            data    => $message
        }
    };

    return $response;

}

sub _rpc_result {
    my ($self, $id, $result) = @_;

    my $response = {
        jsonrpc => RPC_JSON,
        id      => $id,
        result  => $result
    };

    return $response;

}

1;

__END__

=head1 NAME

XAS::Lib::RPC::JSON::Server - A JSON RPC interface for the XAS environment

=head1 SYNOPSIS

 my $server = XAS::Lib::RPC::JSON::Server->new(
     -alias   => 'server',
     -port    => '9505',
     -address => 'localhost',
     -logger  => 'logger'
 );

=head1 DESCRIPTION

This modules implements a simple JSON RPC v2.0 server. It needs to be extended
to be usefull. This runs as a POE session. It doesn't support "Notification" 
calls.

=head1 METHODS

=head2 new

This initializes the module and starts listening for requests. There are
five parameters that can be passed. They are the following:

=over 4

=item B<-alias>

The name of the POE session.

=item B<-port>

The IP port to listen on (default 9505).

=item B<-address>

The address to bind to (default 127.0.0.1).

=item B<-logger>

The name of the logger session.

=back

=head2 process($packet, $wheel)

This method will attempt to parse the JSON RPC packet and call the correct RPC
method. While returning the correct response to the client. 

The method called will be prefixed with "do_". So if the client wants to call 
a "reverse" method, the server will call a "do_reverse" method and return the
response.

=over 4

=item B<$packet>

The packet received from the socket.

=item B<$wheel>

The current POE wheel.

=back

=head2 log($level, $message)

This method will send log message to the logger session.

=over 4

=item B<$level>

The log level.

=item B<$message>

The message to log.

=back

=head1 SEE ALSO

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
