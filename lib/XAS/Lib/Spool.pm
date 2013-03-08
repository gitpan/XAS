package XAS::Lib::Spool;

our $VERSION = '0.02';

use Try::Tiny;
use LockFile::Simple;

use XAS::Class
  version    => $VERSION,
  base       => 'XAS::Base',
  codec      => 'JSON',
  constants  => 'TRUE FALSE',
  filesystem => 'File Dir Path Cwd',
  mutators   => 'packet',
  vars => {
      PARAMS => {
          -spooldir => { 
              callbacks => { 
                  'type checker' => sub {
                      my $p = shift;
                      my $ref = ref($p);

                      return TRUE if ($ref && $p->isa('Badger::Filesystem::Directory'));

                  }
              }
          },
          -extension => { optional => 1, default => '.pkt' },
          -seqfile   => { optional => 1, default => '.SEQ' },
          -lockfile  => { optional => 1, default => 'spool' },
      }
  }
;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub clear {
    my ($self) = @_;

    $self->{packet} = {};

    return 1;

}

sub read {
    my ($self, $filename) = @_;

    my $packet;
    my $data = undef;

    try {

        if ($self->lock()) {

            $packet = $self->read_packet($filename);
            $data = decode($packet);

            $self->unlock();

        } else { 

            $self->throw_msg(
                'xas.lib.spool.read.lock_error',
                'lock_error', 
                $self->spooldir
            );

        }

    } catch {

        my $ex = $_;

        $self->unlock();

        die $ex;

    };

    return $data;

}

sub write {
    my ($self) = @_;

    my $packet;
    my $seqnum;

    try {

        if ($self->lock()) {

            $seqnum = $self->sequence();
            $packet = encode($self->packet);

            $self->write_packet($packet, $seqnum);
            $self->unlock();

        } else { 

            $self->throw_msg(
                'xas.lib.spool.write.lock_error', 
                'lock_error', 
                $self->spooldir
            ); 

        }

    } catch {

        my $ex = $_;

        $self->unlock();

        die $ex;

    };

    return 1;

}

sub scan {
    my ($self) = @_;

    my $dir;
    my $filename;
    my $extension;
    my @files = ();
    my @filenames = ();

    if ($self->lock()) {

        $extension = $self->extension;
        @filenames = $self->spooldir->files;

        foreach $filename (@filenames) {

            if ($filename->name =~ m/$extension/i) {

                push(@files, $filename);

            }

        }

        $self->unlock();

    } else { 

        $self->throw_msg(
            'xas.lib.spool.scan.lock_error', 
            'lock_error', 
            $self->spooldir
        ); 

    }

    return @files;

}

sub delete {
    my ($self, $filename) = @_;

    my $stat = 0;

    if ($self->lock()) {

        $stat = unlink($filename);
        $self->unlock();

    } else { 

        $self->throw_msg(
            'xas.lib.spool.delete.lock_error', 
            'lock_error', 
            $self->spooldir
        ); 

    }

    return $stat;

}

sub count {
    my ($self) = @_;

    my $fh;
    my $filename;
    my $count = 0;
    my $extension = $self->extension;

    if ($self->lock()) {

        $fh = $self->spooldir->open;
        while ($filename = $fh->read) {

            $count++ if ($filename =~ m/$extension/i);

        };

        $fh->close;
        $self->unlock();

    } else { 

        $self->throw_msg(
            'xas.lib.spool.count.lock_error', 
            'lock_error', 
            $self->spooldir
        );

    }

    return $count;

}

sub get {
    my ($self) = @_;

    my $fh;
    my $filename;
    my $extension = $self->extension;

    if ($self->lock()) {

        $fh = $self->spooldir->open;

        while ($filename = $fh->read) {

            last if ($filename =~ m/$extension/i);

        }

        $fh->close;
        $self->unlock();

    } else { 

        $self->throw_msg(
            'xas.lib.spool.get.lock_error', 
            'lock_error', 
            $self->spooldir
        );

    }

    return $filename ? File($self->spooldir, $filename) : undef;

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{lockmgr} = LockFile::Simple->make(
        -format => '%f.lck', 
        -max    => 20,
        -delay  => 1,
        -nfs    => 1,
        -efunc  => undef,
        -wfunc  => undef
    );

    return $self;

}

sub lock {
    my ($self) = @_;

    my $lockfile = File($self->spooldir, $self->lockfile);

    if ($self->{lockmgr}->lock($lockfile->file)) {

        return 1;

    }

    return 0;

}

sub unlock {
    my ($self) = @_;

    my $lockfile = File($self->spooldir, $self->lockfile);

    $self->{lockmgr}->unlock($lockfile->file);

}

sub sequence {
    my ($self) = @_;

    my $fh;
    my $cnt;
    my $seqnum;
    my $file = File($self->spooldir, $self->seqfile);

    try {

        if ($file->exists) {

            $fh = $file->open("r+");
            $seqnum = $fh->getline;
            $seqnum++;
            $fh->seek(0, 0);
            $fh->print($seqnum);
            $fh->close;

        } else {

            $fh = $file->open("w");
            $fh->print("1");
            $fh->close;

            $cnt = chmod(0664, $file);
            $self->throw_msg(
                'xas.lib.spool.sequence.invperms', 
                'invperms', 
                $file
            ) if ($cnt < 1);

            $seqnum = 1;

        }

    } catch {

        my $ex = $_;

        $self->throw_msg(
            'xas.lib.spool.sequence', 
            'sequence', 
            $file
        );

    };

    return $seqnum;

}

sub write_packet {
    my ($self, $packet, $seqnum) = @_;

    my $fh;
    my $cnt;
    my $file = File($self->spooldir, $seqnum . $self->extension);

    try {

        $fh = $file->open("w");
        $fh->print($packet);
        $fh->close;
        $cnt = chmod(0664, $file);

    } catch {

        my $ex = $_;

        $self->throw_msg(
            'xas.lib.spool.write_packet', 
            'write_packet', 
            $file
        );

    };

}

sub read_packet {
    my ($self, $file) = @_;

    my $fh;
    my $packet;

    try {

        $fh = $file->open("r");
        $packet = $fh->getline;
        $fh->close;

    } catch {

        my $ex = $_;
        
        $self->throw_msg(
            'xas.lib.spool.read_packet', 
            'read_packet', 
            $file
        );

    };

    return $packet;

}

1;

__END__

=head1 NAME

XAS::Lib::Spool - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::System;

 my $spl = XAS::System->module(
     spool => {
         -spooldir => 'spool'
     }
 );

 $spl->packet("This is some data");
 $spl->write();

 $spl->clear();
 $spl->packet("This is some other data");
 $spl->write();

 my @files = $spl->scan();

 foreach my $file (@files) {

    my $packet = $spl->read($file);
    print $packet->{data};
    $spl->delete($file);

 }

=head1 DESCRIPTION

This module provides the basic handling of spool files. This module 
provides basic read, write, scan and delete functionality for those files. 

This functionality is designed to be overridden with more specific methods 
for each type of spool file required. 

Individual spool files are stored in sub directories. Since multiple 
processes may be accessing those directories, lock files are being used to 
control access. This is an important requirement to prevent possible race 
conditions between those processes.

A sequence number is stored in the .SEQ file within each sub directory. Each 
spool file will use the ever increasing sequence number as the filename with 
a .pkt extension. To reset the sequence number, just delete the .SEQ file. A 
new file will automatically be created.

The contents of the spool file is a serialized dump of $self->{packet}. It 
uses JSON as the serialization method. JSON was chosen because it is a widely 
known and used format for serializing data structures.

=head1 METHODS

=head2 new

This will initialize the base object. It takes the following parameters:

=over 4

=item B<-spooldir>

This is the directory to use for spool files.

=item B<-lockfile>

The name of the lock file to use. Defaults to 'spool'.

=item B<-extension>

The extension to use on the spool file. Defaults to '.pkt'.

=item B<-seqfile>

The name of the sequence file to use. Defaults to '.SEQ'.

=back

=head2 clear

This will clear the internal data storeage. This method should be 
overridden by the more specific needs of sub classes.

=head2 packet($buffer)

This method will store a buffer into the internal data storage. This buffer
should be something that can be serialized into a JSON formated string.

=head2 write

This will write a new spool file using the interal data storage. Each
evocation of write() will create a new spool file. This method should be 
overridden by the more specific needs of sub classes.

=head2 read($filename)

This will read the contents of spool file and return a data structure. This 
method should be overridden by the more specific needs of sub classes.

Example

    $packet = $spl->read($file);

=head2 scan

This will scan the spool directory looking for items to process. It returns
and array of files to process.

=head2 delete($filename)

This method will delete the file from the spool directory.

=head2 count

This method will return a count of the items in the spool directory.

=head2 get

This method will retreive a filename from the spool directory.

=head1 ACCESORS

=head2 extension

This method will get the current file extension.

=head2 lockfile

This method will get the current lock file name.

=head2 segfile

This method will get the current seguence file name.

=head1 MUTATORS

=head2 spooldir

This method will get/set the current spool directory.

=head1 SEE ALSO

 XAS::Base
 XAS::Class
 XAS::Constants
 XAS::Exception
 XAS::System
 XAS::Utils

 XAS::Apps::Base::Alerts
 XAS::Apps::Base::Collector
 XAS::Apps::Base::ExtractData
 XAS::Apps::Base::ExtractGlobals
 XAS::Apps::Base::RemoveData
 XAS::Apps::Database::Schema
 XAS::Apps::Templates::Daemon
 XAS::Apps::Templates::Generic
 XAS::Apps::Test::Echo::Client
 XAS::Apps::Test::Echo::Server
 XAS::Apps::Test::RPC::Client
 XAS::Apps::Test::RPC::Methods
 XAS::Apps::Test::RPC::Server

 XAS::Collector::Alert
 XAS::Collector::Base
 XAS::Collector::Connector
 XAS::Collector::Factory

 XAS::Lib::App
 XAS::Lib::App::Daemon
 XAS::Lib::App::Daemon::POE
 XAS::Lib::Connector
 XAS::Lib::Counter
 XAS::Lib::Daemon::Logger
 XAS::Lib::Daemon::Logging
 XAS::Lib::Gearman::Admin
 XAS::Lib::Gearman::Admin::Status
 XAS::Lib::Gearman::Admin::Worker
 XAS::Lib::Gearman::Client
 XAS::Lib::Gearman::Client::Status
 XAS::Lib::Gearman::Worker
 XAS::Lib::Net::Client
 XAS::LIb::Net::Server
 XAS::Lib::RPC::JSON::Client
 XAS::Lib::RPC::JSON::Server
 XAS::Lib::Session
 XAS::Lib::Spool

 XAS::Model::Database
 XAS::Model::Database::Alert
 XAS::Model::Database::Counter
 XAS::Model::DBM

 XAS::Monitor::Base
 XAS::Monitor::Database
 XAS::Monitor::Database::Alert

 XAS::Scheduler::Base

 XAS::System::Alert
 XAS::System::Email
 XAS::System::Environment
 XAS::System::Logger

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
