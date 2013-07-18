package XAS::Apps::Templates::Daemon;

use Try::Tiny;
use XAS::Class
  version => '0.01',
  base    => 'XAS::Lib::App::Daemon',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

}

sub main {
    my $self = shift;

    $self->setup();

    $self->log('info', 'Starting up');

    sleep(60);

    $self->log('info', 'Shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Template::Daemon - A template module for daemons within the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Templates::Daemon;

 my $app = XAS::Apps::Templates::Daemon->new();

 exit $app->run();

=head1 DESCRIPTION

This module is a template on a way to write procedures that are daemons
within the XAS enviornment.

=head1 CONFIGURATION

Place your configuration informaion here.

=head1 SEE ALSO

=over 4

=item sbin/daemon-template.pl

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
