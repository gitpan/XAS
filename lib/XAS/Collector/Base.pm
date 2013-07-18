package XAS::Collector::Base;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use XAS::System;
use Params::Validate;

use XAS::Class
  version  => $VERSION,
  base     => 'XAS::Lib::Session',
  mutators => 'schema',
  messages => {
      'intialize'  => "%s: unable to initialize: %s; reason %s",
      'connected'  => "%s: connected to %s on %s",
      'duplicates' => "%s: duplicate key found for: %s",
      'nocolumn'   => "%s: no such column for: %s",
      'badsyntax'  => "%s: invalid input syntax for: %s",
      'nullcolumn' => "%s: null value in column for: %s",
      'toolong'    => "%s: value to long for type: %s",
      'unknown'    => "%s: %s",
      'dbopen'     => "%s: unable to access database: %s; reason: %s",
      'processed'  => "%s: processed %s items from: %s; time: %s"
  },
  vars => {
      PARAMS => {
          -logger    => 1,
          -connector => 1
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

use Data::Dumper;

# ---------------------------------------------------------------------
# Event Handlers
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub initialize {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;

    $self->log('debug', "$alias: entering initialize()");

    try {

        $kernel->state('store_data', $self);
        $self->{schema} = XAS::Model::Database->opendb('database');

    } catch {

        my $ex = $_;

        $self->log('fatal', sprintf('%s', $ex));
        $kernel->yield('shutdown');

    };

    $self->log('debug', "$alias: leaving initialize()");

}

sub cleanup {
    my ($self, $kernel, $session) = @_;

    my $alias = $self->alias;

    $self->log('debug', "$alias: entering cleanup()");

    $self->schema->storage->disconnect;

    $self->log('debug', "$alias: leaving cleanup()");

}

sub exception_handler {
    my ($self, $ex, $dbkey, $buffer) = @_;

    my $skey;
    my $ref = ref($ex);
    my $alias = $self->alias;

    while ( my ($key, $value) = each(%$dbkey)) {

        $skey .= "$key: $value, ";

    }

    chop $skey;
    chop $skey;

    if ($ref) {

        if ($ex->isa('XAS::Exception')) {

            my $text = $ex->info;

            if ($text =~ m/duplicate key/i) {

                $self->log('warn', $self->message('duplicates', $alias, $skey));

            } elsif ($text =~ m/no such column/i) {

                $self->log('error', $self->message('nocolumn', $alias, $skey));
                $self->log('debug', "$alias: " . $text);

            } elsif ($text =~ m/invalid input syntax/i) {

                $self->log('error', $self->message('badsyntax', $alias, $skey));
                $self->log('debug', "$alias: " . $text);

            } elsif ($text =~ m/null value in column/i) {

                $self->log('error', $self->message('nullcolumn', $alias, $skey));
                $self->log('debug', "$alias: " . $text);

            } elsif ($text =~ m/value too long for type/i) {

                $self->log('error', $self->message('toolong', $alias, $skey));
                $self->log('debug', "$alias: " . $text);

            } else {

                $self->log('error', $self->message('unknown', $alias, $text));
                $self->log('debug', Dumper($buffer));

            }

        } else {

            $self->log('error', $self->message('unknown', $alias, $ex));
            $self->log('debug', Dumper($buffer));

        }

    } else {

        $self->log('error', $self->message('unknown', $alias, $ex));
        $self->log('debug', Dumper($buffer));

    }

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Collector::Base - The base class for collectors within the XAS Environment

=head1 SYNOPSIS

  use XAS::Collector::Base;

  my $collector = XAS::Collector::Base->new(
      -connector => 'connector',
      -logger    => 'logger',
  );

=head1 DESCRIPTION

This is the base class for collectors within the XAS environment. This module
will connect to the indicated database and create an event named "store_data".
Modules that inherit from this module need to define what "store_data" does.

=head1 METHODS

=head2 new

This nethod initliazes the modules and takes the following parameters:

=over 4

=item B<-connector>

The name of the connector session. This is used to send ACK's back to the
message queue server.

=item B<-alias>

The name of this POE session.

=item B<-logger>

The name of the logger session. This is used for sending log items too.

=back

=head2 initialize($self, $config)

This method makes the initial connection to the database and defines the 
"store_data" event.

=over

=item B<$self>

A pointer to the current object.

=item B<$config>

Configuration items from new().

=back

=head2 cleanup($self, $kernel, $session)

Closes the connection to the database.

=over 4

=item B<$self>

A pointer to the current object.

=item B<$kernel>

A handle to the POE kernel.

=item B<$session>

A handle to the current POE session.

=back

=head2 log($level, $message)

This method sends log items to the logger session.

=over 4

=item B<$level>

The level of the log action.

=item B<$message>

The message to write to the log.

=back

=head2 exception_handler($ex)

A common exception handler for error reporting.

=over 4

=item B<$ex>

The exception that should be acted upon.

=back

=head1 PUBLIC EVENTS

This module responds to the following POE events.

=head2 store_data

This event will trigger the storage of the packet received from the message 
queue server.

=head2 shutdown

This event will trigger the execution of the cleanup() method.

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
