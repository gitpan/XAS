package XAS::Lib::Daemon::Logging;

our $VERSION = '0.02';

use Params::Validate ':all';

use XAS::Class
  version => $VERSION,
  base    => 'XAS::Base',
  vars => {
      PARAMS => {
          -logger => 1,
          -poe    => 1,
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

sub debug {
    my ($self, $buffer) = @_;

    $self->poe->post($self->logger, 'debug', $buffer);

};

sub info {
    my ($self, $buffer) = @_;

    $self->poe->post($self->logger, 'info', $buffer);

}

sub warn {
    my ($self, $buffer) = @_;

    $self->poe->post($self->logger, 'warn', $buffer);

}

sub error {
    my ($self, $buffer) = @_;

    $self->poe->post($self->logger, 'error', $buffer);

}

sub fatal {
    my ($self, $buffer) = @_;

    $self->poe->post($self->logger, 'fatal', $buffer);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Daemon::Logging - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Daemon::Logging;

 my $log = XAS::Lib::Daemon::Logging->new(
     -logger => 'logger'
     -poe   => $poe_kernel
 );

 $log->info('it works');

=head1 DESCRIPTION

This module simplifies the logging process to XAS::Lib::Daemon::Logger.

=head1 METHODS

=head2 new

This method initializes the module and takes two parameters.

=over 4

=item B<-logger>

The logger to use.

=item B<-poe>

A handle to the POE kernel.

=back

=head2 info($message)

Send "info" log information to the logger.

=head2 warn($message)

Send "warn" log information to the logger.

=head2 error($message)

Send "error" log information to the logger.

=head2 fatal($message)

Send "fatal" log information to the logger.

=head2 debug($message)

Send "debug" log information to the logger.

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
