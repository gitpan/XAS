#!perl -T

use Test::More tests => 57;

BEGIN {
    use_ok( 'XAS::Class' )                        || print "Bail out!";
    use_ok( 'XAS::Constants' )                    || print "Bail out!";
    use_ok( 'XAS::System' )                       || print "Bail out!";
    use_ok( 'XAS::Utils' )                        || print "Bail out!";
    use_ok( 'XAS::Apps::Base::Alerts' )           || print "Bail out!";
    use_ok( 'XAS::Apps::Base::Collector' )        || print "Bail out!";
    use_ok( 'XAS::Apps::Base::ExtractData' )      || print "Bail out!";
    use_ok( 'XAS::Apps::Base::ExtractGlobals' )   || print "Bail out!";
    use_ok( 'XAS::Apps::Base::Spooler' )          || print "Bail out!";
    use_ok( 'XAS::Apps::Base::RemoveData' )       || print "Bail out!";
    use_ok( 'XAS::Apps::Templates::Daemon' )      || print "Bail out!";
    use_ok( 'XAS::Apps::Templates::Generic' )     || print "Bail out!";
    use_ok( 'XAS::Apps::Test::Echo::Client' )     || print "Bail out!";
    use_ok( 'XAS::Apps::Test::Echo::Server' )     || print "Bail out!";
    use_ok( 'XAS::Apps::Test::RPC::Client' )      || print "Bail out!";
    use_ok( 'XAS::Apps::Test::RPC::Methods' )     || print "Bail out!";
    use_ok( 'XAS::Apps::Test::RPC::Server' )      || print "Bail out!";
    use_ok( 'XAS::Collector::Alert' )             || print "Bail out!";
    use_ok( 'XAS::Collector::Base' )              || print "Bail out!";
    use_ok( 'XAS::Collector::Connector' )         || print "Bail out!";
    use_ok( 'XAS::Collector::Factory' )           || print "Bail out!";
    use_ok( 'XAS::Lib::App' )                     || print "Bail out!";
    use_ok( 'XAS::Lib::App::Daemon' )             || print "Bail out!";
    use_ok( 'XAS::Lib::App::Daemon::POE' )        || print "Bail out!";
    use_ok( 'XAS::Lib::Connector' )               || print "Bail out!";
    use_ok( 'XAS::Lib::Counter' )                 || print "Bail out!";
    use_ok( 'XAS::Lib::Daemon::Logger' )          || print "Bail out!";
    use_ok( 'XAS::Lib::Daemon::Logging' )         || print "Bail out!";
    use_ok( 'XAS::Lib::Gearman' )                 || print "Bail out!";
    use_ok( 'XAS::Lib::Gearman::Admin' )          || print "Bail out!";
    use_ok( 'XAS::Lib::Gearman::Admin::Status' )  || print "Bail out!";
    use_ok( 'XAS::Lib::Gearman::Admin::Worker' )  || print "Bail out!";
    use_ok( 'XAS::Lib::Gearman::Client' )         || print "Bail out!";
    use_ok( 'XAS::Lib::Gearman::Client::Status' ) || print "Bail out!";
    use_ok( 'XAS::Lib::Gearman::Worker' )         || print "Bail out!";
    use_ok( 'XAS::Lib::Net::Client' )             || print "Bail out!";
    use_ok( 'XAS::Lib::Net::Server' )             || print "Bail out!";
    use_ok( 'XAS::Lib::RPC::JSON::Client' )       || print "Bail out!";
    use_ok( 'XAS::Lib::RPC::JSON::Server' )       || print "Bail out!";
    use_ok( 'XAS::Lib::Session' )                 || print "Bail out!";
    use_ok( 'XAS::Lib::Spool' )                   || print "Bail out!";
    use_ok( 'XAS::Model::Database' )              || print "Bail out!";
    use_ok( 'XAS::Model::DBM' )                   || print "Bail out!";
    use_ok( 'XAS::Model::Database::Alert' )       || print "Bail out!";
    use_ok( 'XAS::Model::Database::Counter' )     || print "Bail out!";
    use_ok( 'XAS::Monitor::Base' )                || print "Bail out!";
    use_ok( 'XAS::Monitor::Database' )            || print "Bail out!";
    use_ok( 'XAS::Monitor::Database::Alert' )     || print "Bail out!";
    use_ok( 'XAS::Scheduler::Base' )              || print "Bail out!";
    use_ok( 'XAS::Spooler::Connector' )           || print "Bail out!";
    use_ok( 'XAS::Spooler::Factory' )             || print "Bail out!";
    use_ok( 'XAS::Spooler::Processor' )           || print "Bail out!";
    use_ok( 'XAS::System::Alert' )                || print "Bail out!";
    use_ok( 'XAS::System::Email' )                || print "Bail out!";
    use_ok( 'XAS::System::Environment' )          || print "Bail out!";
    use_ok( 'XAS::System::Logger' )               || print "Bail out!";
    use_ok( 'XAS::Base' )                         || print "Bail out!";
}

diag( "Testing XAS::Base $XAS::Base::VERSION, Perl $], $^X" );
