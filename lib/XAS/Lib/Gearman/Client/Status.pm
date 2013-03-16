package XAS::Lib::Gearman::Client::Status;

our $VERSION = '0.02';

use Gearman::XS ':constants';
use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  accessors => 'known status numerator denominator',
  messages => {
      gearman => '%s'
  },
  vars => {
      PARAMS => {
          -handle => 1,
          -jobid  => 1,
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
    my ($ret, $known, $status, $numerator, $denominator) =
      $self->handle->job_status($self->jobid);

    if ($ret != GEARMAN_SUCCESS) {

        $self->throw_msg(
            'xas.lib.gearman.client.status',
            'gearman',
            $self->handle->error
        );

    }

    $self->{known}       = $known;
    $self->{status}      = $status;
    $self->{numerator}   = $numerator;
    $self->{denominator} = $denominator;

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Client::Status - Return the clients status.

=head1 SYNOPSIS

 use XAS:::Lib::Gearman::Client::Status;

 my $status = XAS::Lib::Gearman::Client::Status->new(
     -jobid  => $jobid,
     -handle => $handle
 );

=head1 DESCRIPTION

This module is a wrapper around the Gearman Admin protocol. If returns
an object for the status information returned by the gearman job_status call.

=head1 METHODS

=head2 new

The initializes the module and retireves the status of the job. It takes
two parameters:

=over 4

=item B<-jobid>

The id of the background job.

=item B<-handle>

The handle to the gearman interface.

=back

=head2 known

Returns wither the job is known to gearman.

=head2 status

Returns the status of the job.

=head2 numerator

Returns the numerator of the status.

=head2 denominator

Returns the denominator of the status.

=head1 SEE ALSO

 Gearman::XS
 Gearman::XS::Client
 Gearman::XS::Worker

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
