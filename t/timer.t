use lib 't';
use strict;
use warnings;

use MockServer;
use StatsD::XS 'timer';
use Test::More;

is ref timer, 'StatsD::XS::Timer';

timer->send('foo');

is +MockServer->read, "foo:0|ms\n";

done_testing;
