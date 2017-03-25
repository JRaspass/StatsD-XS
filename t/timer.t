use lib 't';
use strict;
use warnings;

use MockServer;
use StatsD::XS 'timer';
use Sys::Hostname;
use Test::More;

my $host = hostname;

is ref timer, 'StatsD::XS';

{
    timer->send('foo');

    is +MockServer->read, "foo:0|ms\n";
}

{
    local $StatsD::XS::AlsoAppendHost = 1;

    timer->send('foo');

    is +MockServer->read, "foo:0|ms\nfoo.$host:0|ms\n";
}


{
    my $t = timer;

    select undef, undef, undef, .01;

    my @old = @$t;

    $t->reset;

    my @new = @$t;

    ok $old[0] != $new[0] || $old[1] != $new[1];
}

done_testing;
