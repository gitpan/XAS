package XAS::Lib::RPC::JSON::Server;

our $VERSION = '0.03';

use POE;
use Try::Tiny;
use Set::Light;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::Net::Server',
  codec     => 'JSON',
  constants => 'HASH ARRAY :jsonrpc',
  accessors => 'methods',
  messages => {
    'rpc_method'  => "the rpc method \"%s\" is unknown",
    'rpc_version' => "this server supports only json-rpc version 2.0",
    'rpc_format'  => "this json-rpc format is not supported",
    'rpc_batch'   => "the usage of json-rpc batch mode is not supported",
    'rpc_notify'  => "the usage of json-rpc notifications is not supported",
    'nologger'    => 'no logger defined',
  },
  vars => {
    PARAMS => {
      -port => { optional => 1, default => '9505' },
    }
  }
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

sub process_request {
    my ($kernel, $self, $input, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $request;
    my $alias = $self->alias;

    $self->log('debug', "$alias: entering process_request");

    $request = decode($input);

    if (ref($request) eq ARRAY) {

        foreach my $r (@$request) {

            $self->_rpc_request($kernel, $r, $ctx);

        }

    } else {

        $self->_rpc_request($kernel, $request, $ctx);

    }

}

sub process_response {
    my ($kernel, $self, $output, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $json;
    my $alias = $self->alias;

    $self->log('debug', "$alias: entering process_response");

    $json = $self->_rpc_result($ctx->{id}, $output);

    $kernel->yield('client_output', encode($json), $ctx->{wheel});

}

sub process_errors {
    my ($kernel, $self, $output, $ctx) = @_[KERNEL,OBJECT,ARG0,ARG1];

    my $json;
    my $alias = $self->alias;

    $self->log('debug', "$alias: entering process_errors");

    $json = $self->_rpc_error($ctx->{id}, $output->{code}, $output->{message});

    $kernel->yield('client_output', encode($json), $ctx->{wheel});

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

            $self->log('error', $self->message('exception', $type, $info));

        } else {

            my $msg = sprintf("%s", $ex);

            $packet = $self->_rpc_error($id, RPC_ERR_SERVER, $msg);
            $self->log('error', $self->message('unexpected', $msg));

        }

    } else {

        my $msg = sprintf("%s", $ex);

        $packet = $self->_rpc_error($id, RPC_ERR_APP, $msg);
        $self->log('error', $self->message('unexpected', $msg));

    }

    return $packet;

}

sub _rpc_request {
    my ($self, $kernel, $request, $ctx) = @_;

    my $method;
    my $alias = $self->alias;
    
    $self->log('debug', "$alias: _rpc_request: " . Dumper($request));

    try {

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

        if ($self->methods->has($request->{method})) {

            $ctx->{id} = $request->{id};
            $self->log('debug', "$alias: performing \"" . $request->{method} . '"');

            $kernel->post($alias, $request->{method}, $request->{params}, $ctx);

        } else {

            $self->throw_msg(
                'xas.lib.rpc.json.server.rpc_method', 
                'rpc_method', 
                $request->{method}
            );

        }

    } catch {

        my $ex = $_;

        my $output = $self->_exception_handler($ex, $request->{id});
        $kernel->yield('client_output', encode($output), $ctx->{wheel});

    };

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

XAS::Lib::RPC::JSON::Server - A simple JSON RPC server

=head1 SYNOPSIS

 my $server = XAS::Lib::RPC::JSON::Server->new(
     -alias   => 'server',
     -port    => '9505',
     -address => 'localhost',
     -logger  => 'logger'
 );

=head1 DESCRIPTION

This modules implements a simple JSON RPC v2.0 server. It needs to be extended
to be useful. This runs as a POE session. It doesn't support "Notification" 
calls. It inherits from L<XAS::Lib::Net::Server>.

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

=head2 methods

A handle to a L<Set::Light> object that contains the methods 
that can be evoked.

=head1 PUBLIC EVENTS

Events are used to handle processing.

=head2 process_request($kernel, $self, $input, $ctx)

This method will attempt to parse the JSON RPC request packet and call the 
correct RPC method. 

=over 4

=item B<$kernel>

The handle to the POE kernel.

=item B<$self>

The handle to the current object.

=item B<$input>

The input to parse and create a json packet from.

=item B<$ctx>

The context of this call.

=back

=head2 process_response($kernel, $self, $input, $ctx)

This method will attempt to parse the response and return the correct JSON
RPC results packet to the client. 

=over 4

=item B<$kernel>

The handle to the POE kernel.

=item B<$self>

The handle to the current object.

=item B<$output>

The out to parse and create a json response from.

=item B<$ctx>

The context of this call.

=back

=head2 process_errors($kernel, $self, $output, $ctx)

This method will attempt to parse the response and return the correct JSON
RPC error packet to the client. 

=over 4

=item B<$kernel>

The handle to the POE kernel.

=item B<$self>

The handle to the current object.

=item B<$output>

The output to parse and create a json response from. This needs to have
"code" and "message" fields.

=item B<$ctx>

The context of this call.

=back

=head1 SEE ALSO

=over 4

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
