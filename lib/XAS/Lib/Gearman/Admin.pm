package XAS::Lib::Gearman::Admin;

our $VERSION = '0.02';

use Set::Light;
use IO::Socket::INET;
use Params::Validate ':all';
use XAS::Lib::Gearman::Admin::Status;
use XAS::Lib::Gearman::Admin::Worker;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => 'trim',
  accessors => 'socket',
  constant => {
      XVERSION => 'version',
      STATUS   => 'status',
      WORKERS  => 'workers',
      MAXQUEUE => 'maxqueue',
      SHUTDOWN => 'shutdown',
      PINGPONG => 'ping? pong!',
  },
  messages => {
      noset   => 'unable to set maxqueue',
      pingerr => "echo string mismatch: got \"%s\", expected \"%s\"",
      connerr => 'unable to connect to server: errno - %s',
      readerr => 'unable to read from socket: errno - %s',
      writerr => 'unable to write to socket: errno - %s',
  },
  vars => {
      PARAMS => {
          -server => { optional => 1, default => 'localhost' },
          -port   => { optional => 1, default => 4730 },
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

sub connect {
    my $self = shift;

    $self->{socket} = IO::Socket::INET->new(
        PeerAddr => $self->server,
        PeerPort => $self->port
    ) or $self->throw(
        'xas.lib.gearman.admin.connect',
        'connerr',
        $!
    );

}

sub disconnect {
    my $self = shift;

    $self->socket->close();

}

sub shutdown {
    my $self = shift;

    my $buffer;
    my $sock = $self->socket;

    my %p = validate(@_,
        {
            '-graceful' => {optional => 1, default => ''}
        }
    );

    $buffer = sprintf("%s %s\n", SHUTDOWN, $p{'-graceful'});
    print {$sock} $buffer;

}

sub ping {
    my $self = shift;

    my $rv;
    my $res;
    my $blen;
    my $type = 16;
    my $arg = PINGPONG;
    my $len = length($arg);
    my $start_time = time();
    my $buffer = "\0REQ" . pack("NN", $type, $len) . $arg;

    $blen = length($buffer);

    $self->socket->clearerr();
    $rv = $self->socket->syswrite($buffer, $blen);
    unless ($rv) {

        $self->throw_msg(
            'xas.lib.gearman.admin.ping.write',
            'writerr',
            $self->socket->error()
        );

    }

    sleep(1);

    $self->socket->clearerr();
    $rv = $self->socket->sysread($res, $blen);
    unless ($rv) {

        $self->throw_msg(
            'xas.lib.gearman.admin.ping.read',
            'readerr',
            $self->socket->error()
        );

    }

    $buffer = substr($res, 12, $blen - 12);

    unless ($buffer eq $arg) {

        $self->throw_msg(
            'xas.lib.gearman.admin.ping',
            'pingerr',
            $buffer, $arg
        );

    }

    return time() - $start_time;

}

sub set_maxqueue {
    my $self = shift;

    my $buffer;
    my $sock = $self->socket;

    my %p = validate(@_,
        {
            -queue => 1,
            -size     => 1
        }
    );

    $buffer = sprintf("%s %s %s\n", MAXQUEUE, $p{'-queue'}, $p{'-size'});
    print {$sock} $buffer;
    my $res = <$sock>;

    $res = trim($res);

    if ($res ne 'OK') {

        $self->throw_msg(
            'xas.lib.gearman.admin.set_maxqueue',
            'noset'
        );

    }

}

sub get_version {
    my $self = shift;

    my $sock = $self->socket;
    my $buffer = sprintf("%s\n", XVERSION);

    print {$sock} $buffer;
    my $ver = <$sock>;

    return trim($ver);

}

sub get_status {
    my $self = shift;

    my %p = validate(@_,
        {
            -queue => {optional => 1, default => 'all'},
        }
    );

    my @cols;
    my $sock = $self->socket;
    my $buffer = sprintf("%s\n", STATUS);
    my @values = split(',', $p{'-queue'});
    my $set = Set::Light->new(@values);

    print {$sock} $buffer;

    while (my $line = <$sock>) {

        last if $line eq ".\n";

        my $status = XAS::Lib::Gearman::Admin::Status->new(
            -line => $line
        );

        if (($set->has($status->queue)) or ($set->has('all'))) {

            push(@cols, $status);

        }

    }

    return wantarray ? @cols : \@cols;

}

sub get_workers {
    my $self = shift;

    my %p = validate(@_,
        {
            -queue => {optional => 1, default => 'all'},
        }
    );

    my @cols;
    my $sock = $self->socket;
    my $buffer = sprintf("%s\n", WORKERS);
    my @values = split(',', $p{'-queue'});
    my $set = Set::Light->new(@values);

    print {$sock} $buffer;

    while (my $line = <$sock>) {

        last if $line eq ".\n";

        my $worker = XAS::Lib::Gearman::Admin::Worker->new(
            -line => $line
        );

        if (($set->has($worker->queue)) or ($set->has('all'))) {

            push(@cols, $worker);

        }

    }

    return wantarray ? @cols : \@cols;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Gearman::Admin - An interface to the Gearman job queue.

=head1 SYNOPSIS

 use XAS:::Lib::Gearman::Admin;

 my $client = XAS::Lib::Gearman::Admin->new(
     -server => 'localhost',
     -port   => '4730'
 );

=head1 DESCRIPTION

This module is a wrapper around the Gearman Admin protocol. If unifies common
methods with error handling to make main line code easier to work with.

=head1 METHODS

=head2 new

This method initializes the module, it doesn't make a connection to the
gearman server. It takes two parameters:

=over 4

=item B<-server>

The server that gearman is running on, defaults to 'localhost'.

=item B<-port>

The IP port that geraman is listening on, defaults to 4730.

=back

=head2 connect

Connect to gearman.

=head2 disconnet

Disconnect from gearman.

=head2 shutdown

Tell gearman to shutdown. It takes one optional parameter:

=over 4

=item B<-graceful>

Do the shutdown gracefully.

=back

=head2 ping

Send a "ping" to gearman. This will tell if the server is functioning.

=head2 set_maxqueue

Set the maximum number of workers for a queue. It takes two parameters:

=over 4

=item B<-queue>

The name of the queue.

=item B<-size>

The number of workers.

=back

=head2 get_version

Returns the current version of the gearman server.

=head2 get_status

Retrieves the current status of queues on gearman. Depending on context, it can
return an array or a reference to an array of L<XAS::Lib::Gearman::Admin::Status|XAS::Lib::Gearman::Admin::Status>
objects. It takes one optional parameter:

=over 4

=item B<-queue>

The name of the queue for the status request.

=back

=head2 get_workers

This method returns the workers attached to gearman. Depending on 
context, it can return an array or a reference to an array of 
L<XAS::Lib::Gearmam::Admin:::Worker|XAS::Lib::Gearmam::Admin:::Worker> objects. It takes one optional parameter:

=over 4

=item B<-queue>

The name of the queue for the worker request.

=back

=head1 SEE ALSO

 Gearman::XS
 Gearman::XS::Client
 Gearman::XS::Worker

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
