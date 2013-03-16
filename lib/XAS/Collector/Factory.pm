package XAS::Collector::Factory;

our $VERSION = '0.03';

use Config::IniFiles;
use Params::Validate ':all';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base Badger::Prototype',
  utils     => 'load_module',
  constants => 'XAS_QUEUE',
  accessors => 'collectors queues types',
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
    my @types;
    my @queues;
    my @sections;
    my @collectors;
    my $filename = $p{'-configs'}->path;

    if ($cfg = Config::IniFiles->new(-file => $filename)) {

        @sections = $cfg->Sections;

        foreach my $section (@sections) {

            next if ($section !~ /^collector:/);

            my $module = $cfg->val($section, 'module');

            load_module($module);

            my $collector = $module->new(
                -alias     => $cfg->val($section, 'alias'),
                -connector => $p{'-connector'},
                -logger    => $p{'-logger'},
            );

            push(@types, {
                $cfg->val($section, 'packet-type'),
                $cfg->val($section, 'alias')
            });
            push(@queues, $cfg->val($section, 'queue', XAS_QUEUE));
            push(@collectors, $collector);

        }

    } else {

        $self->throw_msg(
            'xas.colletor.factory.load.badini', 
            'badini', 
            $p{'-configs'}
        );

    }

    $self->{types} = \@types;
    $self->{queues} = \@queues;
    $self->{collectors} = \@collectors;

    return $self;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Collector::Factory - A factory method to load collector processors

=head1 SYNOPSIS

This module is used to create multiple collectors from a configuration file.

 my $collectors = XAS::Collector::Factory->load(
    -connector => 'connector',
    -logger    => 'logger',
    -configs   => 'collectors.ini'
 );

=head1 DESCRIPTION

This module will take a configuration file and starts all the collectors 
defined within. 

=head2 Configuration File

The configuraton file has the following cavets:

=over 4

=item B<o> Item names are case sensitve.

=item B<o> A ";" indicates the start of a comment.

=item B<o> The section header must be unique and start with "collector:".

=back

The file format follows the familiar Win32 .ini format. 

  ; My configuration file
  ;
  [collector: alert]
  alias = alert
  queue = /queue/alert
  packet-type = xas-alert
  module = XAS::Collector::Alert

=head2 Configuration Items

=over 4

=item B<alias>

The alias for the POE Session.

=item  B<packet-type>

The XAS packet type. Defaults to 'unknown'.

=item B<module>

The module to load to handle this packet type.

=item B<queue>

The queue to listen on for packets. Defaults to '/queue/xas'.

=back

=head1 METHODS

=head2 load

This loads the configuration file and starts the collectors.

=head1 ACCESSORS

=head2 collectors

Returns a list of collectors.

=head2 queues

Returns a list of queues that will be listened on.

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
