package XAS::Docs::Theory;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

XAS::Docs::Theory - theory of operation for the XAS environment

=head1 DESCRIPTION

A system with well defined interfaces and objectives is fairly reliable on a 
single system. Distribute that same system over muliple systems and it becomes
inherently unreliable. Why? B<You do not have control over intermediary "thingies" between those systems>. 
You may think you do, but you don't. At any given time something will fail. 
This is a given, accept it and plan for it.

With that being said, this environment tries to be reliable. 

=head2 Reliablity

Reliablily starts from the ground up. You should have a consitent call 
interface within your modules. You should have a well defined interfaces 
between your modules. When your modules are combined into procedures they 
should have consistent exception handling, option handling and return known
exit codes to the command line when ran. When procedures comunicate between
themselves they should all use the same standard protocols. There should be
no surprises. When you start doing this you start to have a reliable system. 

And you can do this in any programming language. There really is nothing in
any particular language that makes it more "reliable". Sure, some have some 
built in capablities for this, but it all comes down to a discplined 
programmer. A displined programmer can write good, reliable, software in
any language, a undisplined one can't, it is a simple as that. 

=head2 Operation

This is loosely coupled environment. There is no direct one-to-one 
communications between procedures. A message queue is used as a intermediary
between them. This is done for a reason. It makes the endpoints simpler. They
don't have to maintain an internal queue of messages with all the management
overhead. It can be pushed off to a dedicated process and that process can 
exist anywhere within the environment. Here is a diagram of how this 
environment works.

                    (message queue server)
                         /         \
                        /           \
     +----+            /             \               +----+
     |    |           /               \              |    |
     |    |-->[spooler]                [collector]-->|    |
     |    |                                          |    |
     +----+                                          +----+
    datastore                                       datastore

The spooler is standalone. It knows its local environment and how to 
communicate to the message queue. When it sends a message all it knows is
that it reached its destination. It is responsible for maintaining the local
datastore.

The collector also is standalone. It knows its local environment and how 
to communicate to the message queue. When it receives a message it does 
something with it. 

This is known as "store and forward" messaging. It is a reliable, tried and 
true way to send something across a network. 

=head2 Self Healing

In this environment, if a "thingie" falls off the network. The messages queue 
up, ready to be deliveried when the "thingie" comes back online. When the 
message queue server is configured to store messages in a backing store, 
you will not loose messages.

Which makes the environment reliable.

=head1 SEE ALSO

 XAS

=head1 AUTHOR

Kevin L. Esteb, C<< <kevin (at) kesteb.us> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kevin L. Esteb, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
