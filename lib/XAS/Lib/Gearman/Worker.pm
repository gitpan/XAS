package XAS::Lib::Gearman::Worker;

our $VERSION = '0.02';

use Params::Validate ':all';
use Gearman::XS ':constants';

use XAS::Class
  version  => $VERSION,
  base     => 'XAS::Lib::Gearman',
  codec    => 'JSON',
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

sub work {
    my ($self) = shift;

    my $ret = $self->handle->work();
    if (($ret != GEARMAN_SUCCESS) && ($ret != GEARMAN_UNEXPECTED_PACKET)) {

        $self->throw_msg(
            'xas.lib.gearman.worker.work',
            'gearman',
            $self->handle->error
        );

    }

}

sub add_function {
    my $self = shift;

    my %p = validate(@_,
        {
            -queue    => 1,
            -function => { type => CODEREF },
            -options  => { optional => 1, default => {} },
        }
    );

    my $ret = $self->handle->add_function(
        $p{'-queue'},
        0,
        $p{'-function'},
        $p{'-options'}
    );
    if ($ret != GEARMAN_SUCCESS) {

        $self->throw_msg(
            'xas.lib.gearman.worker.add_function',
            'gearman',
            $self->handle->error
        );

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($class, $config) = @_;

    $config->{'-module'} = 'Gearman::XS::Worker';
    my $self = $class->SUPER::init($config);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Worker - An interface to the Gearman job queue.

=head1 SYNOPSIS

 use XAS::Lib::Gearman::Worker;

 sub reverse {
    my $job = shift;

    ....
    ....

 }

 my $worker = XAS::Lib::Gearman::Worker->new(
     -server => 'localhost',
     -port   => '4730'
 );

 $worker->add_function(
     -queue    => 'reverse',
     -function => \&reverse,
     -options  => {}
 );
 
 while ($worker->work());

=head1 DESCRIPTION

This is a wrapper module around L<Gearman::XS::Worker|Gearman::XS::Worker>.

=head1 METHODS

=head2 new

This method intializes the module and connects to the gearman server. It
takes two parameters:

=over 4

=item B<-server>

The server where gearman resides, defaults to 'localhost'.

=item B<-port>

The IP port that gearman is listening on, defaults to 4730.

=back

=head2 work

This method is used to wait for work from gearman. It handles some common
error conditions. It will throw an exception when something unexpected 
happens.

=head2 add_function

Notify gearman that we can handle this function. It takes three parameters:

=over 4

=item B<-queue>

The queue that this procedure will listen on.

=item B<-function>

The callback that will do the work.

=item B<-options>

Optional options to be passed to gearman.

=back

=head1 SEE ALSO

 Gearman::XS
 Gearman::XS::Client
 Gearman::XS::Worker

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
