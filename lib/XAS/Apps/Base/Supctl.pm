package XAS::Apps::Base::Supctl;

use XAS::Supervisor::RPC::Client;
use XAS::Class
  version => '0.02',
  base    => 'XAS::Lib::App',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    my $result;
    my $rpc = XAS::Supervisor::RPC::Client->new(
        -port => $self->port,
        -host => $self->host
    );

    if (defined($self->reload)) {

        $result = $rpc->reload($self->reload);

    } elsif (defined($self->start)) {

        $result = $rpc->start($self->start);

    } elsif (defined($self->stop)) {

        $result = $rpc->stop($self->stop);

    } elsif (defined($self->status)) {

        $result = $rpc->status($self->status);

    }

    $self->log('info', $result);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Base::Supctl - control program for the XAS Supervisor

=head1 SYNOPSIS

 use XAS::Apps::Base::Supctl;

 my $app = XAS::Apps::Base::Supctl->new(
     -options => [
         { 'host=s'   => 'localhost' },
         { 'port=s'   => '9505' }
         { 'start=s'  => undef },
         { 'stop=s'   => undef },
         { 'status=s' => undef },
         { 'reload=s' => undef }
     ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module provides a simple control interface to the XAS Supervisor. This
module inheirs from L<XAS::Lib::App>.

=head1 CONFIGURATION

=head2 -options

This provides additional options. There format is what can be supplied to
Getopt::Long. The defaults are the supplied values. Those values be can 
overridden on the command line.

=over 4

=item B<'host=s'>

This is the host that the supervisor resides on.

=item B<'port=s'>

This is the port that it listens too.

=item B<'start=s'>

Send a start request for the named process.

=item B<'stop=s'>

Send a stop request for the named process.

=item B<'reload=s'>

Send a reload request for the named process.

=item B<'status=s'>

Send a status request for the named process.

=back

=head1 SEE ALSO

=over 4

=item bin/xas-supctl.pl

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
