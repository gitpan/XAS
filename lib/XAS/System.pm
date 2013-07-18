package XAS::System;

our $VERSION = '0.01';

use Badger::Factory::Class
  version    => $VERSION,
  item       => 'module',
  path       => 'XAS::System XAS::Lib',
  modules => {
      logger      => 'XAS::System::Logger',
      alert       => 'XAS::System::Alert',
      email       => 'XAS::System::Email',
      environment => 'XAS::System::Environment',
      spool       => 'XAS::Lib::Spool',
  }
;

1;

__END__
  
=head1 NAME

XAS::System - A factory system for the XAS environment

=head1 SYNOPSIS

You can use this module in the following manner.

 use XAS::System;

 my $xas = XAS::System->module('environment');

 ... or ...

 my $xas = XAS:System->module('Environment');

Either of the above statements will load the XAS::System::Environment module.

=head1 DESCRIPTION

This module is a factory system for the XAS environment. It will load and
initialize modules on demand. The advantage is that you don't need to load
all your modules at the beginning of your program. You also don't need to
know where individual modules live. And this system can provide a nice alias 
for long module names. This should lead to cleaner more readable programs.

=head1 SHORTCUTS

The following are shortcut names that can be used.

=head2 logger

This will load the XAS::System::Logger module.

=head2 alert

This will load the XAS::System::Alert module.

=head2 email

This will load the XAS::System::Email module.

=head2 enviroment

This will load the XAS::System::Environment module.

=head2 spool

This will load the XAS::Lib::Spool module.

=head1 METHODS

=head2 module

This method loads the named module and passes any parameters to that module.

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
