package XAS::Base;

use 5.8.8;

our $VERSION = '0.01';
our $EXCEPTION = 'XAS::Exception';
our ($SCRIPT)  = ( $0 =~ m#([^\\/]+)$# );

use XAS::System;
use XAS::Exception;
use Params::Validate ':all';

use XAS::Class
  base     => 'Badger::Base',
  version  => $VERSION,
  accessors => 'env',
  messages => {
    exception     => "%s: %s",
    dberror       => "a database error has occurred: %s",
    invparams     => "invalid parameters passed, reason: %s",
    nospooldir    => "no spool directory defined",
    noschema      => "no database schema was defined",
    unknownos     => "unknown OS: %s",
    unexpected    => "unexpected error: %s",
    unknownerror  => "unknown error: %s",
    nodbaccess    => "unable to access database: %s; reason %s",
    undeliverable => "unable to send mail to %s; reason: %s",
    noserver      => "unable to connect to %s; reason: %s",
    nodelivery    => "unable to send message to %s; reason: %s",
    sequence      => "unable to retrieve sequence number from %s",
    write_packet  => "unable to write a packet to %s",
    read_packet   => "unable to read a packet from %s",
    lock_error    => "unable to acquire a lock on %s",
    invperms      => "unable to change file permissions on %s",
    badini        => "unable to load config file: %s",
    expiredacct   => 'this accounts expiration day has passed',
    expiredpass   => 'this accounts password has expired',
    sessionend    => 'the session has expired',
    noaccess      => 'you are not able to access the system at this time',
    loginattempts => 'you have exceeded your login attempts',
  },
  vars => {
    PARAMS => {
      -alerts => { optional => 1, default => 0 },
      -xdebug => { optional => 1, default => 0 },
      -logger => { optional => 1, default => undef },
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

sub config {
    my ($class, $p) = @_;

    return $class->{config}->{$p};

}

sub validation_exception {
    my $param = shift;
    my $class = shift;

    $param = lcfirst($param);
    $class =~ s/::/./g;
    $class = lc($class) . '.invparams';

    __PACKAGE__->throw_msg($class, 'invparams', $param);

}

sub log {
    my $self = shift;
    my ($level, $message) = validate_pos(@_,
        { regex => qr/info|warn|error|fatal|debug/i },
        1
    );

    if ($self->logger) {

        $self->logger->info($message)  if (lc($level) eq 'info');
        $self->logger->warn($message)  if (lc($level) eq 'warn');
        $self->logger->error($message) if (lc($level) eq 'error');
        $self->logger->fatal($message) if (lc($level) eq 'fatal');
        $self->logger->debug($message) if (lc($level) eq 'debug');

    } else {

        unless ((lc($level) eq 'debug') && (! $self->xdebug)) {

            warn sprintf("%-5s - %s\n", uc($level), $message);

        }

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $self = shift;

    my $params = $self->class->hash_vars('PARAMS');
    my %p = validate(@_, $params);

    $self->{config} = \%p;
    $self->{env} = XAS::System->module('environment');

    no strict "refs";               # to register new methods in package
    no warnings;                    # turn off warnings

    while (my ($key, $value) = each(%p)) {

        $key =~ s/^-//;

        next if ($key eq 'env');
        next if ($key eq 'log');

        $self->{$key} = $value;

        *$key = sub {
            my $self = shift;
            return $self->{$key};
        };

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Base - The base class for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Base',
   vars => {
       PARAMS => {}
   }
 ;

=head1 DESCRIPTION

This module defines a base class for the XAS Environment and inherits from
L<Badger::Base|Badger::Base>. The package variable $PARAMS is used to hold 
the parameters that this class uses for initialization. The parameters can be 
changed or extended by inheriting classes. This is functionality provided by 
L<Badger::Class|Badger::Class>. The parameters are validated using 
L<Params::Validate|Params::Validate>. Any parameters defined in $PARAMS 
automagically become accessors toward their values.

=head1 METHODS

=head2 new($parameters)

This is used to initialized the class. It takes various parameters defined by
the $PARAMS package variable. 

=head2 config($item)

This method will return an item from the internal class config. Which is 
usually the parameters passed to new() before any manipulation of those
parameters.

=over 4

=item B<$item>

The item you want to return,

=back

=head2 validation_exception($params, $class)

This method is used by L<Params::Validate|Params::Validate> to display it's 
failure message.

=over 4

=item B<$params>

The parameter that caused the exception.

=item B<$class>

The class that it happened in.

=back

=head2 env

A handle to L<XAS::System::Environment|XAS::System::Environment>.

=head2 log($level, $message)

A basic logger.

=over 4

=item B<$level>

The level for the message. This can be 'info', 'warn', 'error', 'fatal' and
'debug'.

=item B<$message>

The message to write to the log.

=back


=head1 SEE ALSO

=over 4

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
