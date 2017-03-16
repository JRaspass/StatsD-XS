use strict;
use warnings;

use StatsD::XS qw/inc/;
use Test::More;

$StatsD::XS::Host = 'foo';

inc 'foo';

pass;

done_testing;
