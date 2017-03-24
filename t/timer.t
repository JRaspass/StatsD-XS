use lib 't';
use strict;
use warnings;

use MockServer;
use StatsD::XS 'timer2';
use Test::More;

my $timer = timer2;

is ref $timer, 'StatsD::XS::Timer';

$timer->send2;

is +MockServer->read, "foo\n";

done_testing;
