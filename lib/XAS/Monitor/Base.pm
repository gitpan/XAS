package XAS::Monitor::Base;

our $VERSION = '0.02';

use POE;
use Params::Validate;

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Lib::Session',
  vars => {
      PARAMS => {
          -logger => 1,
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

sub log {
    my ($self, $level, $message) = @_;

    my $logger = $self->logger;

    $poe_kernel->post($logger, $level, $message);

}

sub exception_handler {
    my ($self, $ex) = @_;

    my $msg;
    my $ref = ref($ex);

    if ($ref) {

        if ($ex->isa('XAS::Exception')) {

	    my $type = $ex->type;
	    my $info = $ex->info;

            $msg = sprintf("%s: %s", $type, $info);

        } else {

            $msg = sprintf("%s", $msg);

        }

    } else {

        $msg = sprintf("%s", $ex);

    }

    $self->log('error', $msg);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Monitor::Base - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Monitor::Base',
 ;

=head1 DESCRIPTION

This module is the base class for monitor modules. It provides common routines
that are needed by the other modules.

=head1 METHODS

=head2 log($level, $message)

This method sends log items to the logger session. It takes two parameters:
level and message. Where level is one supported by your logger.

=over 4

=item B<$level>

The log level to use.

=item B<$message>

The entry to write to the log file.

=back

=head2 exception_handler($ex)

A common exception handler for error reporting. It takes one parameter, 
the exception.

=over 4

=item B<$ex>

The exception that is to be handled.

=back

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
