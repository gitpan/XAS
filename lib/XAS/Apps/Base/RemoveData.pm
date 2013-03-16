package XAS::Apps::Base::RemoveData;

our $VERSION = '0.01';

use Try::Tiny;
use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::App',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub parse_file {
    my $self = shift;

    my $fh;

    open($fh, "<", $self->file);

    LOOP:
    while (<$fh>) {

        if ($_ =~ m/^COPY \w+ \(/) {

            while (<$fh>) {

                next LOOP if ($_ =~ m/^\\\./);

            }

        }

        print $_;

    }

}

sub main {
    my $self = shift;

    $self->log->debug('Starting main section');

    $self->parse_file();

    $self->log->debug('Ending main section');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Base::RemoveData - This module will remove data from a postgres dump file

=head1 SYNOPSIS

 use XAS::Apps::Base::RemoveData;

 my $app = XAS::Apps::Base::RemoveData->new(;
    -throws  => 'pg_remove_data',
    -options => [
        {'file=s' => ''},
    ]
 );

 exit $app->run();

=head1 DESCRIPTION

This module will strip the "copy" statements from a postgres pg_dumpall file. 
Thus producing a schema that is suitable to rebuild an "empty" database.

=head1 CONFIGURATION

The following parameters are used to configure the module.

=head2 -options

Defines the command line options for this module. 

=over 4

=item B<'files=s'>

Defines the dump file to use.

=back

=head1 SEE ALSO

 bin/pg_remove_data.pl

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
