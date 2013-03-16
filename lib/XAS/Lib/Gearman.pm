package XAS::Lib::Gearman;

our $VERSION = '0.02';

use Try::Tiny;
use Gearman::XS ':constants';
use Params::Validate ':all';

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Base',
  accessors  => 'handle',
  utils      => 'load_module',
  messages => {
      gearman => '%s'
  },
  vars => {
      PARAMS => {
          -server => { optional => 1, default => 'localhost' },
          -port   => { optional => 1, default => '4730' },
          -module => 1,
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
    my $ret;

    try {

        load_module($self->module);
        $self->{handle} = $self->module->new();

    } catch {

        my $ex = $_;

        $self->throw_msg(
            'xas.lib.gearman.new',
            'gearman',
            'unable to load ' . $self->module
        );

    };

    if ($self->server =~ m/[,:]/) {

        $ret = $self->handle->add_servers($self->server);
        if ($ret != GEARMAN_SUCCESS) {

            $self->throw_msg(
                'xas.lib.gearman.new',
                'gearman',
                $self->handle->error
            );

        }

    } else {

        $ret = $self->handle->add_server($self->server, $self->port);
        if ($ret != GEARMAN_SUCCESS) {

            $self->throw_msg(
                'xas.lib.gearman.new',
                'gearman',
                $self->handle->error
            );

        }

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Gearman - An interface to the Gearman job queue system.

=head1 SYNOPSIS

 use XAS::Class
     version => '0.01',
     base    => 'XAS::Lib::Gearman'
 ;

=head1 DESCRIPTION

This is the base class for XAS::Lib::Gearman::Client and
XAS::Lib::Gearman::Worker.

=head1 METHODS

=head2 new

This module will load the indicated module and initialize it. It take one
parameter with three optional ones.

=over 4

=item B<-module>

This parameter is mandatory. It is the module to load and initialize.

=item B<-server>

An optional server to connect too. Defaults to 'localhost'. This may be
a comma seperated list of hosts and port numbers. 

Example

   -server => 'localhost:4730,remotehost:9600'

=item B<-port>

An optional IP port to connect too.

=back

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
