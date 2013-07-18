package XAS::Lib::Mixin::Locking;

our $VERSION = '0.01';

use Params::Validate ':all';

use XAS::Class
  base       => 'Badger::Mixin XAS::Base',
  version    => $VERSION,
  filesystem => 'File Dir',
  mixins     => 'lock_directory unlock_directory lock_directories unlock_directories lock_file_name',
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

sub lock_directory {
    my $self = shift;
    my ($name) = validate_pos(@_,
        { isa => 'Badger::Filesystem::Directory' },
    );

    my $lock = $self->lock_file_name($name);

    return $self->lockmgr->lock($lock);

}

sub unlock_directory {
    my $self = shift;    
    my ($name) = validate_pos(@_,
        { isa => 'Badger::Filesystem::Directory' },
    );

    my $lock = $self->lock_file_name($name);

    $self->lockmgr->unlock($lock);

}

sub lock_directories {
    my $self = shift;

    my ($sdir, $ddir) = validate_pos(@_, {
        { isa => 'Badger::Filesystem::Directory' },
        { isa => 'Badger::Filesystem::Directory' },
    });

    my $stat = 0;

    if ($self->lock_directory($sdir)) {

        if ($self->lock_directory($ddir)){

            $stat = 1;

        } else {

            $self->unlock_directory($sdir);

        }

    }

    return $stat;

}

sub unlock_directories {
    my $self = shift;

    my ($sdir, $ddir) = validate_pos(@_, {
        { isa => 'Badger::Filesystem::Directory' },
        { isa => 'Badger::Filesystem::Directory' },
    });

    $self->unlock_directory($sdir);
    $self->unlock_directory($ddir);

}

sub lock_file_name {
    my $self = shift;
    my ($directory) = validate_pos(@_,
        { isa => 'Badger::Filesystem::Directory' },
    );

    my $lock = File($directory->canonical, 'locked');

    return $lock->path;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixin::Locking - A mixin to provide discretionary locking.

=head1 SYNOPSIS

 use LockFile::Simple;

 use XAS::Class
    version  => '0.01',
    base     => 'XAS::Base',
    accessor => 'lockmgr',
    mixins   => 'XAS::Lib::Mixin::Locking'
 ;

 sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{lockmgr} = LockFile::Simple->make(
        -format => '%f.lck',
        -max    => 20,
        -delay  => 1,
        -nfs    => 1,
        -stale  => 1,
        -hold   => 900,
        -wfunc  => sub { my $msg = shift; $self->log('warn', $msg); },
        -efunc  => sub { my $msg = shift; $self->log('error', $msg); }
    );

    return $self;
  
 }

 sub main {

    if ($self->lock_directories($source, $destination)) {

        $self->unlock_directories($source, $destination);

    }

 }

=head1 DESCRIPTION

This module provides discretionary directory locking. This is to coordinate 
access to directories by multiple processes. These locks are advisory. It is
implemented as a mixin. This module also needs an accessor named 'lockmgr'
initilaized by L<LockFile::Simple>.

=head1 METHODS

=head2 lock_directory($directory)

This method will lock a single directory. It takes these parameters:

=over 4

=item B<$directory>

The directory to use when locking.

=back

=head2 unlock_directory($directory)

This method will unlock a single directory. It takes these parameters:

=over 4

=item B<$directory>

The directory to use when unlocking.

=back

=head2 lock_directories($source, $destination)

This method will attempt to lock the source and destination directories.
It takes these parameters:

=over 4

=item B<$source>

The source directory.

=item B<$destination>

The destination directory.

=back

=head2 unlock_directories($source, $destination)

This method will unlock the source and destination directories. It takes
these parameters:

=over 4

=item B<$source>

The source directory.

=item B<$destination>

The destination directory.

=back

=head2 lock_file_name($directory)

This method returns the locks filename. It can be overridden if needed.
The default name is 'locked'. It takes the following parameters:

=over 4

=item B<$directory>

The directory the lock file resides in.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
