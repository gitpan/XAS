package XAS::Supervisor::RPC::Client;

our $VERSION = '0.03';

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::RPC::JSON::Client',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub start {
    my ($self, $name) = @_;

    my $result;
    my $params = {
        name => $name
    };

    $result = $self->call(
        -method => 'start_process', 
        -id     => $self->id,
        -params => $params
    );

    return $result;

}

sub stop {
    my ($self, $name) = @_;

    my $result;
    my $params = {
        name => $name
    };

    $result = $self->call(
        -method => 'stop_process', 
        -id     => $self->id,
        -params => $params
    );

    return $result;

}

sub reload {
    my ($self, $name) = @_;

    my $result;
    my $params = {
        name => $name
    };

    $result = $self->call(
        -method => 'reload_process', 
        -id     => $self->id,
        -params => $params
    );

    return $result;

}

sub status {
    my ($self, $name) = @_;

    my $result;
    my $params = {
        name => $name
    };

    $result = $self->call(
        -method => 'stat_process', 
        -id     => $self->id,
        -params => $params
    );

    return $result;

}

sub stop_supervisor {
    my ($self) = @_;

    my $result;

    $result = $self->call(
        -method => 'stop_supervisor',
        -id     => $self->id,
        -params => {}
    );

    return $result;

}

sub id {
    my $self = shift;

    $self->{id}++;

    return $self->{id};

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{id} = 0;

    return $self;

}

1;

__END__

=head1 NAME

XAS::Supervisor::RPC::Client - The RPC interface to the XAS Supervisor

=head1 SYNOPSIS

 use XAS::Supervisor::RPC::Client;

 my $rpc = XAS::Supervisor::RPC::Client->new()
 my $result = $rpc->start('sleeper');

=head1 DESCRIPTION

This is the client module for external access to the XAS Supervisor. It provides
methods to start/stop/reload and retrieve the status of managed processes. This
module inheirts from L<XAS::Lib::RPC::JSON::Client|XAS::Lib::RPC::JSON::Client>.

=head1 METHODS

=head2 new

This initilaize the module and can take these parameters.

 Example:

     my $rpc = XAS::Supervisor::RPC::Client->new(
        -port => 9505,
        -host => 'localhost'
     };

=head2 start($name)

This method will start a managed process. It takes one parameter, the name
of the process, and returns "started" if successful.

 Example:

     my $result = $rpc->start('sleeper');

=head2 stop($name)

This method will stop a managed process. It takes one parameter, the name of
the process, and returns "stopped" if successful.

 Example:

     my $result = $rpc->stop('sleeper');

=head2 status($name)

This method will do a "stat" on a managed process. It takes one parameter,
the name of the process, and returns "alive" if the process is running or 
"dead" if the process is not.

=head2 reload($name)

This method will attempt to "reload" a managed process. It takes one parameter,
the name of the process. It will return "reloaded".

 Example:

     my $result = $rpc->reload('sleeper');

=head1 SEE ALSO

=over 4

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
