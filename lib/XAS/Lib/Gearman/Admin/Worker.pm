package XAS::Lib::Gearman::Admin::Worker;

our $VERSION = '0.02';

use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim',
  accessors => 'fd address client queue',
  messages => {
      invline => 'invalid line format',
  },
  vars => {
      PARAMS => {
          -line => 1,
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

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);
    my $line = trim($self->line);

    if ($line =~ /^(\d+)\s+(\S+)\s+(\S+)\s+:\s*(.*)$/) {

        $self->{fd}      = $1;
        $self->{address} = $2;
        $self->{client}  = $3;
        $self->{queue}   = $4;

    } else {

        $self->throw_msg(
            'xas.lib.gearman.admin.worker',
            'invline'
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Admin::Worker - An interface to the Gearman job queue.

=head1 SYNOPSIS

 use XAS:::Lib::Gearman::Admin::Worker;

 my $client = XAS::Lib::Gearman::Admin::Worker->new(
     -line => $line
 );

=head1 DESCRIPTION

This module is a wrapper around the Gearman Admin protocol. If unifies common
methods with error handling to make main line code easier to work with.

=head1 METHODS

=head2 fd 

Returns the fd number.

=head2 address 

Returns the IP address of the client.

=head2 client 

Returns the clients name.

=head2 function

Returns the function the worker performs.

=head1 SEE ALSO

 Gearman::XS
 Gearman::XS::Client
 Gearman::XS::Worker

L<XAS|XAS>

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut