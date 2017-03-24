use lib 't';
use strict;
use warnings;

use MockServer;
use StatsD::XS;
use Test::More;

sub foo : Time { select undef, undef, undef, .01 }

foo();

like +MockServer->read, qr/^main\.foo:\d+\|ms\n$/;

done_testing;
