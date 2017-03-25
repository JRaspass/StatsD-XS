use lib 't';
use strict;
use warnings;

use MockServer;
use StatsD::XS 'gauge';
use Sys::Hostname;
use Test::More;

my $host = hostname;

gauge 'foo', 123;

is +MockServer->read, "foo:123|g\n", 'gauge "foo", 123';

gauge 'foo.bar', 456;

is +MockServer->read, "foo.bar:456|g\n", 'inc "foo.bar", 456';

local $StatsD::XS::AlsoAppendHost = 1;

gauge 'baz', 789;

is +MockServer->read, "baz:789|g\nbaz.$host:789|g\n",
    'local $StatsD::XS::AlsoAppendHost = 1; inc "baz", 789';

done_testing;
