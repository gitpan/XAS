package XAS::Apps::Base::Alerts;

our $VERSION = '0.03';

use POE;
use Try::Tiny;
use XAS::System;
use XAS::Lib::Daemon::Logger;
use XAS::Monitor::Database::Alert;

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Lib::App::Daemon::POE',
  accessors => 'email'
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    $self->{email} = XAS::System->module(
        email => {
            -server => $self->env->mxserver,
            -port   => $self->env->mxport,
        }
    );

}

sub main {
    my $self = shift;

    my $alert;
    my $logger;

    $self->setup();

    $logger = XAS::Lib::Daemon::Logger->new(
        -alias  => 'logger',
        -logger => $self->log
    );

    $alert = XAS::Monitor::Database::Alert->new(
        -alias     => 'alert',
        -logger    => 'logger',
        -mailer    => $self->email,
        -email_to   => "kevin\@kesteb.us",
        -email_from => "xas\@" . $self->env->host . '.' . $self->env->domain,
        -schedule => '*/15 * * * *',
    );

    $self->log->info("Starting up");

    $poe_kernel->run();

    $self->log->info('Shutting down');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Base::Alerts - This module will monitor the alerts table

=head1 SYNOPSIS

 use XAS::Apps::Base::Alerts;

 my $app = XAS::Apps::Base::Alerts->new();

 exit $app->run();

=head1 DESCRIPTION

This module will monitor the alerts table within the XAS database. When pending
alerts are found they are emailed to a support person. It inherits from
XAS::Lib::App::Daemon::POE.

=head1 SEE ALSO

 XAS::Daemon::Logger
 XAS::Lib::App::Daemon
 XAS::Lib::App::Daemon::POE
 XAS::Monitor::Database::Alert

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
