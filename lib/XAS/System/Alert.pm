package XAS::System::Alert;

our $VERSION = '0.03';

use DateTime;
use Try::Tiny;
use Params::Validate ':all';

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Base',
  codec      => 'JSON',
  utils      => 'dt2db',
  accessors  => 'spooler',
  filesystem => 'Dir'
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

sub send {
    my $self = shift;

    my %p = validate(@_, 
        { 
            -message  => 1,
            -facility => { optional => 1, default => 'systems' },
            -priority => { optional => 1, default => 'low', regex => qr/low|medium|high/ }, 
        }
    );

    my $dt = DateTime->now(time_zone => 'local');

    my $data = {
        hostname => $self->env->host,
        datetime => dt2db($dt),
        priority => $p{'-priority'},
        facility => $p{'-facility'},
        message  => $p{'-message'},
    };

    $self->spooler->packet($data);
    $self->spooler->write();

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $spooldir = Dir($self->env->spool, 'alerts');

    $self->{spooler} = XAS::System->module(
        spool => {
            -spooldir => $spooldir,
            -mask     => 0777,
        }
    );

    return $self;

}

1;

__END__

=head1 NAME

XAS::System::Alert - The alert module for the XAS environment

=head1 SYNOPSIS

Your program can use this module in the following fashion:

 use XAS::System;

 my $alert = XAS::System->module('alert');

 $alert->send(
     -priority => 'high',
     -facility => 'huston',
     -message  => 'There is a problem'
 );

=head1 DESCRIPTION

This is the module for sending alerts within the XAS environment. 

=head1 METHODS

=head2 new

This method initializes the module. It is automatically called when invoked
by XAS::System->module().

=head2 send

This method will send an alert. It takes the following named parameters:

=over 4

=item B<-priority>

The notification level, 'high','medium','low'. Default 'low'.

=item B<-facility>

The notification facility, 'systems', 'dba', etc.  Default 'systems'.

=item B<-message>

The message text for the message

=back

=head1 SEE ALSO

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
