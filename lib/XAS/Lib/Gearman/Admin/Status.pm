package XAS::Lib::Gearman::Admin::Status;

our $VERSION = '0.02';

use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim',
  accessors => 'queue total running available',
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

    if ($line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)$/) {

        $self->{queue}     = $1;
        $self->{total}     = $2;
        $self->{running}   = $3;
        $self->{available} = $4;

    } else {

        $self->throw_msg(
            'xas.lib.gearman.admin.status.invline',
            'invline'
        );

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Admin::Status - An interface to the Gearman job queue.

=head1 SYNOPSIS

 use XAS:::Lib::Gearman::Admin::Status;

 my $status = XAS::Lib::Gearman::Admin::Status->new(
     -line => $line
 );

=head1 DESCRIPTION

This module is a wrapper around the Gearman Admin protocol. If unifies common
methods with error handling to make main line code easier to work with.

=head1 ACCESSORS

=head2 queue 

Returns the queue.

=head2 total 

Returns the total number of workers.

=head2 running 

Returns the number that are running.

=head2 available

Returns the number that are available.

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