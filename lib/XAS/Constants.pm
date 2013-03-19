package XAS::Constants;

our $VERSION = '0.02';

use Badger::Exporter;

use Badger::Class
  version => $VERSION,
  base    => 'Badger::Constants',    # grab the badger constants
  constant => {
      AVAILABLE  => 'Available',
      DELETE     => 'Delete',
      XAS_QUEUE  => '/queue/xas',

      # PBS Status vaules

      SUBMIT     => 'Submit',
      SUBMITTED  => 'Submitted',
      UNKNOWN    => 'Unknown',
      QUEUED     => 'Queued',
      COMPLETED  => 'Completed',
      EXITING    => 'Exiting',
      RUNNING    => 'Running',
      MOVING     => 'Moving',
      WAITING    => 'Waiting',
      SUSPENDED  => 'Suspended',
  
      # Workman

      JOBSTATS  => '/queue/jobstats',

      # JSON RPC

      RPC_JSON            => '2.0',
      RPC_DEFAULT_ADDRESS => '127.0.0.1',
      RPC_DEFAULT_PORT    => '9505',
      RPC_ERR_PARSE       => -32700,
      RPC_ERR_REQ         => -32600,
      RPC_ERR_METHOD      => -32601,
      RPC_ERR_PARAMS      => -32602,
      RPC_ERR_INTERNAL    => -32603,
      RPC_ERR_SERVER      => -32099,
      RPC_ERR_APP         => -32001,
      RPC_SRV_ERR_MIN     => -32000,
      RPC_SRV_ERR_MAX     => -32768,

      # Curses screen stuff

      LABEL_F1  => 'F1=Help',
      LABEL_F2  => 'F2=Yes',
      LABEL_F3  => 'F3=Exit',
      LABEL_F4  => 'F4=No',
      LABEL_F5  => 'F5=Refresh',
      LABEL_F6  => 'F6=Left',
      LABEL_F7  => 'F7=Bkwd',
      LABEL_F8  => 'F8=Fwd',
      LABEL_F9  => 'F9=Right',
      LABEL_F10 => 'F10=Actions',
      LABEL_F11 => 'F11=Select',
      LABEL_F12 => 'F12=Cancel',

  },
  exports => {
      all => q/AVAILABLE DELETE UNKNOWN QUEUED COMPLETED EXITING RUNNING 
               MOVING WAITING SUSPENDED SUBMIT SUBMITTED JOBSTATS RPC_JSON 
               RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE RPC_ERR_REQ 
               RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL RPC_ERR_SERVER 
               RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP LABEL_F1 LABEL_F2 
               LABEL_F3 LABEL_F4 LABEL_F5 LABEL_F6 LABEL_F7 LABEL_F8 LABEL_F9 
               LABEL_F10 LABEL_F11 LABEL_F12 XAS_QUEUE/,
      any => q/AVAILABLE DELETE UNKNOWN QUEUED COMPLETED EXITING RUNNING 
               MOVING WAITING SUSPENDED SUBMIT SUBMITTED JOBSTATS RPC_JSON 
               RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE RPC_ERR_REQ 
               RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL RPC_ERR_SERVER 
               RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP LABEL_F1 LABEL_F2 
               LABEL_F3 LABEL_F4 LABEL_F5 LABEL_F6 LABEL_F7 LABEL_F8 LABEL_F9 
               LABEL_F10 LABEL_F11 LABEL_F12 XAS_QUEUE/,
      tags => {
          batch   => 'UNKNOWN QUEUED COMPLETED EXITING RUNNING MOVING WAITING SUSPENDED AVAILABLE DELETE SUBMIT SUBMITTED',
          workman => 'UNKNOWN COMPLETED RUNNING AVAILABLE SUBMIT SUBMITTED JOBSTAT',
          jsonrpc => q/RPC_JSON RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE 
                      RPC_ERR_REQ RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL 
                      RPC_ERR_SERVER RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP/,
          labels  => q/LABEL_F1 LABEL_F2 LABEL_F3 LABEL_F4 LABEL_F5 LABEL_F6
                      LABEL_F7 LABEL_F8 LABEL_F9 LABEL_F10 LABEL_F11 
                      LABEL_F12/,
      }
  }
;

1;

__END__

=head1 NAME

XAS::Constants - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
     base => 'XAS::Base',
     constant => 'TRUE FALSE'
 ;

 ... or ...

 use XAS::Constants 'TRUE FALSE';

=head1 DESCRIPTION

This module provides various constants for the XAS enviromnet. It inherits from
L<Badger::Constants|Badger::Constants> and also provides those constants.

=head2 EXPORT

 AVAILABLE DELETE UNKNOWN QUEUED COMPLETED EXITING RUNNING 
 MOVING WAITING SUSPENDED SUBMIT SUBMITTED JOBSTATS RPC_JSON 
 RPC_DEFAULT_PORT RPC_DEFAULT_ADDRESS RPC_ERR_PARSE RPC_ERR_REQ 
 RPC_ERR_METHOD RPC_ERR_PARAMS RPC_ERR_INTERNAL RPC_ERR_SERVER 
 RPC_SRV_ERR_MAX RPC_SRV_ERR_MIN RPC_ERR_APP LABEL_F1 LABEL_F2 
 LABEL_F3 LABEL_F4 LABEL_F5 LABEL_F6 LABEL_F7 LABEL_F8 LABEL_F9 
 LABEL_F10 LABEL_F11 LABEL_F12

 Along with these tags

 batch
 workman
 jsonrpc
 labels

=head1 SEE ALSO

L<XAS|XAS>

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut