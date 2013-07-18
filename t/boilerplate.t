#!perl -T

use strict;
use warnings;
use Test::More tests => 73;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

TODO: {
  local $TODO = "Need to replace the boilerplate text";

  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/XAS/Base.pm');
  module_boilerplate_ok('lib/XAS/Class.pm');
  module_boilerplate_ok('lib/XAS/Constants.pm');
  module_boilerplate_ok('lib/XAS/System.pm');
  module_boilerplate_ok('lib/XAS/Utils.pm');
  module_boilerplate_ok('lib/XAS/Apps/Base/Alerts.pm');
  module_boilerplate_ok('lib/XAS/Apps/Base/Collector.pm');
  module_boilerplate_ok('lib/XAS/Apps/Base/ExtractData.pm');
  module_boilerplate_ok('lib/XAS/Apps/Base/ExtractGlobals.pm');
  module_boilerplate_ok('lib/XAS/Apps/Base/Spooler.pm');
  module_boilerplate_ok('lib/XAS/Apps/Base/Supervisor.pm');
  module_boilerplate_ok('lib/XAS/Apps/Base/Supctl.pm');
  module_boilerplate_ok('lib/XAS/Apps/Base/RemoveData.pm');
  module_boilerplate_ok('lib/XAS/Apps/Templates/Daemon.pm');
  module_boilerplate_ok('lib/XAS/Apps/Templates/Generic.pm');
  module_boilerplate_ok('lib/XAS/Apps/Test/Echo/Client.pm');
  module_boilerplate_ok('lib/XAS/Apps/Test/Echo/Server.pm');
  module_boilerplate_ok('lib/XAS/Apps/Test/RPC/Client.pm');
  module_boilerplate_ok('lib/XAS/Apps/Test/RPC/Methods.pm');
  module_boilerplate_ok('lib/XAS/Apps/Test/RPC/Server.pm');
  module_boilerplate_ok('lib/XAS/Collector/Alert.pm');
  module_boilerplate_ok('lib/XAS/Collector/Base.pm');
  module_boilerplate_ok('lib/XAS/Collector/Connector.pm');
  module_boilerplate_ok('lib/XAS/Collector/Factory.pm');
  module_boilerplate_ok('lib/XAS/Lib/App.pm');
  module_boilerplate_ok('lib/XAS/Lib/App/Daemon.pm');
  module_boilerplate_ok('lib/XAS/Lib/App/Daemon/POE.pm');
  module_boilerplate_ok('lib/XAS/Lib/Connector.pm');
  module_boilerplate_ok('lib/XAS/Lib/Counter.pm');
  module_boilerplate_ok('lib/XAS/Lib/Daemon/Logger.pm');
  module_boilerplate_ok('lib/XAS/Lib/Daemon/Logging.pm');
  module_boilerplate_ok('lib/XAS/Lib/Gearman.pm');
  module_boilerplate_ok('lib/XAS/Lib/Gearman/Admin.pm');
  module_boilerplate_ok('lib/XAS/Lib/Gearman/Admin/Status.pm');
  module_boilerplate_ok('lib/XAS/Lib/Gearman/Admin/Worker.pm');
  module_boilerplate_ok('lib/XAS/Lib/Gearman/Client.pm');
  module_boilerplate_ok('lib/XAS/Lib/Gearman/Client/Status.pm');
  module_boilerplate_ok('lib/XAS/Lib/Gearman/Worker.pm');
  module_boilerplate_ok('lib/XAS/Lib/Net/Client.pm');
  module_boilerplate_ok('lib/XAS/Lib/Net/Server.pm');
  module_boilerplate_ok('lib/XAS/Lib/Mixin/Env.pm');
  module_boilerplate_ok('lib/XAS/Lib/Mixin/Locking.pm');
  module_boilerplate_ok('lib/XAS/Lib/Mixin/Handlers.pm');
  module_boilerplate_ok('lib/XAS/Lib/RPC/JSON/Client.pm');
  module_boilerplate_ok('lib/XAS/Lib/RPC/JSON/Server.pm');
  module_boilerplate_ok('lib/XAS/Lib/Session.pm');
  module_boilerplate_ok('lib/XAS/Lib/Spool.pm');
  module_boilerplate_ok('lib/XAS/Lib/Stomp/Frame.pm');
  module_boilerplate_ok('lib/XAS/Lib/Stomp/Parser.pm');
  module_boilerplate_ok('lib/XAS/Lib/Stomp/Utils.pm');
  module_boilerplate_ok('lib/XAS/Lib/Stomp/POE/Client.pm');
  module_boilerplate_ok('lib/XAS/Lib/Stomp/POE/Filter.pm');
  module_boilerplate_ok('lib/XAS/Model/Database.pm');
  module_boilerplate_ok('lib/XAS/Model/DBM.pm');
  module_boilerplate_ok('lib/XAS/Model/Database/Base/Alert.pm');
  module_boilerplate_ok('lib/XAS/Model/Database/Base/Counter.pm');
  module_boilerplate_ok('lib/XAS/Monitor/Base.pm');
  module_boilerplate_ok('lib/XAS/Monitor/Database.pm');
  module_boilerplate_ok('lib/XAS/Monitor/Database/Alert.pm');
  module_boilerplate_ok('lib/XAS/Scheduler/Base.pm');
  module_boilerplate_ok('lib/XAS/Supervisor/Controller.pm');
  module_boilerplate_ok('lib/XAS/Supervisor/Factory.pm');
  module_boilerplate_ok('lib/XAS/Supervisor/Process.pm');
  module_boilerplate_ok('lib/XAS/Supervisor/RPC/Client.pm');
  module_boilerplate_ok('lib/XAS/Spooler/Connector.pm');
  module_boilerplate_ok('lib/XAS/Spooler/Factory.pm');
  module_boilerplate_ok('lib/XAS/Spooler/Processor.pm');
  module_boilerplate_ok('lib/XAS/System/Alert.pm');
  module_boilerplate_ok('lib/XAS/System/Email.pm');
  module_boilerplate_ok('lib/XAS/System/Environment.pm');
  module_boilerplate_ok('lib/XAS/System/Logger.pm');

}

