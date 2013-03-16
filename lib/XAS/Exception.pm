package XAS::Exception;

use base Badger::Exception;
$Badger::Exception::TRACE = 1;

1;

__END__

=head1 NAME

XAS::Exception - The base exception class for the XAS environment

=head1 DESCRIPTION

This module defines a base exception class for the XAS Environment and 
inherits from Badger::Exception. The only differences is that it turns
stack tracing on by default.

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
