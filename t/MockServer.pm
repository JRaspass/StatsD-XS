package MockServer;

use strict;
use warnings;

use IO::Socket::INET;
use StatsD::XS;

my $sock = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    Proto     => 'udp',
) or die "Unable to create socket: $!\n";

$StatsD::XS::Port = $sock->sockport;

sub read {
    $sock->recv( my $data, 1024 );
    $data;
}

1;
