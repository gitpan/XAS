package XAS::Apps::Database::Schema;

use XAS::Model::Database;

use XAS::Class
  version => '0.02',
  base    => 'XAS::Lib::App',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    $self->{schema} = XAS::Model::Database->opendb('database');

}

sub main {
    my $self = shift;

    $self->log->info('Starting up');
    $self->setup();

    $self->{schema}->create_ddl_dir(
        [$self->dbtype],
        $self->revision,
        $self->directory,
    );

    $self->log->info('Shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Database::Schema - Create a database schema

=head1 SYNOPSIS

 use XAS::Apps::Database::Schema;

 my $app = XAS::Apps::Database::Schema->new();

 exit $app->run();

=head1 DESCRIPTION

This module will create a schema for the XAS database.

=head1 SEE ALSO

 bin/create_schema.pl

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
