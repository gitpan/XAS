package XAS::Lib::Counter;

our $VERSION = '0.02';

use Params::Validate ':all';
use XAS::Model::Database 'Counter';

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Base',
  vars => {
      PARAMS => {
          -database => 1,
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

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub inc {
    my ($self, $name) = @_;

    my $value = 1;
    my $criteria = {
        name => $name
    };

    $self->schema->txn_do(sub {

       if (my $rec = Counter->find_or_create($self->database, $criteria)) {

           $value = $rec->value + 1;

           $rec->value($value);
           $rec->update;

       }

    });

    return $value;

}

sub dec {
    my ($self, $name) = @_;

    my $value = 1;
    my $criteria = {
        name => $name
    };

    $self->schema->txn_do(sub {

       if (my $rec = Counter->find_or_create($self->database, $criteria)) {

           if ($rec->value > 1) {

               $value = $rec->value - 1;

           }

           $rec->value($value);
           $rec->update;

       }

    });

    return $value;

}

sub value {
    my ($self, $name) = @_;

    my $value = 1;
    my $criteria = {
        name => $name
    };

    $self->schema->txn_do(sub {

       if (my $rec = Counter->find($self->database, $criteria)) {

           $value = $rec->value;

       }

    });

    return $value;

}

sub reset {
    my ($self, $name) = @_;

    my $value = 1;
    my $criteria = {
        name => $name
    };

    $self->schema->txn_do(sub {

       if (my $rec = Counter->find_or_create($self->database, $criteria)) {

           $rec->value($value);
           $rec->update;

       }

    });

    return $value;

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Counter - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Counter;

 my $counter = XAS::Lib::Counter->new(
    -database = $database
 );

 my $value = $counter->inc('jobid');
 my $value = $counter->dec('jobid');
 my $value = $counter->value('jobid');
 my $value = $counter->reset('jobid');

=head1 DESCRIPTION

This module will maintain a table of counters. These counters are numeric and
start from 1.

=head1 METHODS

=head2 new

This will initialize the base object. It takes the following parameters:

=over 4

=item B<-database>

This is the database schema where the Counter table resides.

=back

=head2 inc($name)

This will increment the named counter by one and return the result.

=over 4

=item B<$name>

The name of the counter.

=back

=head2 dec($name)

This will decrement the named counter by one and return the result;

=over 4

=item B<$name>

The name of the counter.

=back

=head2 reset($name)

This will reset the named counter to one and return the result.

=over 4

=item B<$name>

The name of the counter.

=back

=head2 value($name)

This will return the current value of the named counter.

=over 4

=item B<$name>

The name of the counter.

=back

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
