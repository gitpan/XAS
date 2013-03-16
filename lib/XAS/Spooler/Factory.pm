package XAS::Spooler::Factory;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use Config::IniFiles;
use XAS::Spooler::Processor;
use Params::Validate 'validate';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base Badger::Prototype',
  accessors => 'processors queues',
  constants => 'XAS_QUEUE',
  messages => {
      badini => 'unable to load config file: %s',
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

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub shutdown {
    my $self = shift;

    my $processors = $self->processors;

    foreach my $processor (@$processors) {

        my $alias = $processor->alias;
        $poe_kernel->call($alias, 'shutdown');

    }

}

sub stop_scan {
    my $self = shift;
    
    my $processors = $self->processors;

    foreach my $processor (@$processors) {

        my $alias = $processor->alias;
        $poe_kernel->call($alias, 'stop_scan');

    }

}

sub start_scan {
    my $self = shift;

    my $processors = $self->processors;

    foreach my $processor (@$processors) {

        my $alias = $processor->alias;
        $poe_kernel->call($alias, 'start_scan');

    }

}

sub load {
    my $self = shift;

    $self = $self->prototype() unless ref $self;

    my %p = validate(@_,
        {
            -connector => 1,
            -logger    => 1,
            -configs   => 1,
        }
    );

    my $cfg;
    my @queues;
    my @sections;
    my @processes;
    my $filename = $p{'-configs'}->path;

    if ($cfg = Config::IniFiles->new(-file => $filename)) {

        @sections = $cfg->Sections;

        foreach my $section (@sections) {

            next if ($section !~ /^spooler:/);

            my $processor = XAS::Spooler::Processor->new(
                -logger      => $p{'-logger'},
                -connector   => $p{'-connector'},
                -alias       => $cfg->val($section, 'alias', 'spooler'),
                -directory   => $cfg->val($section, 'directory', ''),
                -schedule    => $cfg->val($section, 'schedule', '*/1 * * * *'),
                -packet_type => $cfg->val($section, 'packet-type', 'unknown'),
            );

            push(@queues, {
                type  => $cfg->val($section, 'packet-type', 'unknown'),
                queue => $cfg->val($section, 'queue', XAS_QUEUE)
            });
            push(@processes, $processor);

        }

    } else {

        $self->throw_msg(
            'xas.spooler.processorfactory.load.badini', 
            'badini', 
            $p{'-configs'}
        );

    }

    $self->{queues} = \@queues;
    $self->{processors} = \@processes;

    return $self;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Spooler::Factory - A factory method to load spool processors

=head1 SYNOPSIS

This module is used to create multiple spool processeors from a 
configuration file.

 my $processor = XAS::Spooler::Factory->load(
    -connector => 'connector',
    -logger    => 'logger',
    -config    => 'spools.ini'
 );

=head1 DESCRIPTION

This module will take a configuration file and start all the spool 
processeors defined within. The file format follows the familiar Win32 .ini 
format. 

  ; My configuration file
  ;
  [spool:nmon]
  alias = alert
  directory = alerts
  schedule = '*/1 * * * *'
  queue = /queue/xas
  packet-type = xas-alert

=over 4

=item B<o> Item names are case sensitve.

=item B<o> A ";" indicates the start of a comment.

=item B<o> The section header must be unique and start with "spool:".

=back

These configuration items have corresponding parameters in 
L<XAS::Spooler::Processor|XAS::Spooler::Processor>.

=head2 ITEMS

=over 4

=item B<alias>

The alias for the POE Session. Defaults to 'spooler'.

=item B<directory>

The spool directory to monitor. It defaults to the root of the XAS spool 
directory.

=item B<schedule>

A cron style schedule to use when scanning the directory. Defaults to
'*/1 * * * *'.

=item  B<packet-type>

The DDC packet type. Defaults to 'unknown'.

=item B<queue>

The queue to send the message too. Defaults to '/queue/xas'.

=back

=head1 METHODS

=head2 load

This loads the configuration file and starts the spool processors.

=head2 shutdown

This method will shutdown the spool processors.

=head2 stop_scan

This method will stop the scanning process of the spool processors.

=head2 start_scan

This method will start the scanning process of the spool processors.

=head1 SEE ALSO

 XAS

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
