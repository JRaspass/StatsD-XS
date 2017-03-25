use lib 't';
use strict;
use warnings;

use MockServer;
use StatsD::XS 'timer';
use Test::More;

is ref timer, 'StatsD::XS';

{
    timer->send('foo');

    is +MockServer->read, "foo:0|ms\n";
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
