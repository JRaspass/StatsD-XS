use lib 't';
use strict;
use warnings;

use MockServer;
use StatsD::XS qw/inc/;
use Sys::Hostname;
use Test::More;

my $host = hostname;

inc 'foo';

is +MockServer->read, "foo:1|c\n", 'inc "foo"';

inc 'foo.bar';

is +MockServer->read, "foo.bar:1|c\n", 'inc "foo.bar"';

local $StatsD::XS::AlsoAppendHost = 1;

inc 'baz';

is +MockServer->read, "baz:1|c\nbaz.$host:1|c\n",
    'local $StatsD::XS::AlsoAppendHost = 1; inc "baz"';

done_testing;
