use lib 't';
use strict;
use warnings;

use MockServer;
use StatsD::XS;
use Test::More;

sub foo : Time {}

foo();

is +MockServer->read, 'foo';

done_testing;
