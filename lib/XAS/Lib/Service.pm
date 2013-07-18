package XAS::Lib::Service;

our $VERSION = '0.01';

use Params::Validate;

use WPM::Class
  base     => 'XAS::Lib::Session',
  version  => $VERSION,
  messages => {
    noservice => 'unable to start service; reason: %s',
    paused    => 'the service is already paused',
    unpaused  => 'the service is not paused',
  },
  vars => {
    PARAMS => {
      -poll_interval     => { optional => 1, default => 2 },
      -shutdown_interval => { optional => 1, default => 25 },
    }
  }
;

Params::Validate::validation_options(
    on_fail => sub {
        my $params = shift;
        my $class  = __PACKAGE__;
        XAS::Base::validation_exception($params, $class);
    }
);

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub service_startup {
    my $self = shift;

    $self->log('info', 'service startup');

}

sub service_shutdown {
    my $self = shift;

    $self->log('info', 'service shutdown');

}

sub service_running {
    my $self = shift;

    $self->log('info', 'service running');

}

sub service_paused {
    my $self = shift;

    $self->log('info', 'service paused');

}

sub service_unpaused {
    my $self = shift;

    $self->log('info', 'service continue');

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Overridden Methods - semi public
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Service - A base class for Services

=head1 SYNOPSIS

 use XAS::Lib::Service;

 my $sevice = XAS::Lib::Service->new(
    -logger => $log,
 );

=head1 DESCRIPTION

This module defines an interface to services. A service is a managed 
background process.

=head1 METHODS

=head2 new()

This method is used to initialize the service. 

=over 4

=item B<--poll_interval>

The number of seconds between polls. Defaults to 5.

=item B<--shutdown_interval>

The number of seconds before shutdown can happen. Defaults to 25. 

=back

It also use parameters from WPM::Lib::Session.

=head2 service_startup()

This method should be overridden, it is called when the service is
starting up.

=head2 service_shutdown()

This method should be overridden, it is called when the service has
been stopped or when the system is shutting down.

=head2 service_running()

This method should be overridden, it is called every B<--poll_interval>.
This is where the work of the service can be done.

=head2 service_paused()

This method should be overridden, it is called when the service has been
paused.

=head2 service_unpaused()

This method should be overridden, it is called when the service has been
resumed.

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
