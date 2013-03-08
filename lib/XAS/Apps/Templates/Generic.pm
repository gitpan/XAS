package XAS::Apps::Templates::Generic;

use Try::Tiny;
use XAS::Class
  version => '0.02',
  base    => 'XAS::Lib::App',
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

    $self->log->info('Starting up');

    sleep(10);

    $self->log->info('Shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Templates::Generic - A template module for generic processes

=head1 SYNOPSIS

 use XAS::Apps::Templates::Generic;

 my $app = XAS::Apps::Templates::Generic->new();

 exit $app->run();

=head1 DESCRIPTION

This module is a template on a way to write procedures 
within the XAS enviornment.

=head1 CONFIGURATION


=head1 SEE ALSO

 XAS::Lib::App
 XAS::Lib::App::Daemon
 XAS::Lib::App::Daemon::POE

 XAS::Apps::Templates::Daemon

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
