package StatsD::XS 0.001;

use strict;
use warnings;

use B;
use IO::Socket::INET;
use Sys::Hostname;
use Time::HiRes;
use XSLoader;

use constant HOST_SUFFIX => '.' . hostname;

XSLoader::load();

# Allow callers to add stats relative to host.
our $AlsoAppendHost;

our $Host = '127.0.0.1';
our $Port = 8125;

sub import {
    shift;

    my $pkg = caller . '::';

    no strict 'refs';

    *{ $pkg . $_ } = \&$_ for @_;

    *{ $pkg . 'MODIFY_CODE_ATTRIBUTES' } = sub {
        my ( $pkg, $code, @attrs, @unhandled ) = @_;

        my $prefix = $pkg =~ s/::/./gr . '.';

        for (@attrs) {
            if ( $_ ne 'Time' ) {
                push @unhandled, $_;
                next;
            }

            my $name = B::svref_2object($code)->GV->NAME;
            my $stat = $prefix . $name;

            no strict 'refs';
            no warnings 'redefine';

            # TODO Hide this sub from caller, would be much easier under XS.
            *{"$pkg\::$name"} = sub {
                my $t = timer();

                if (wantarray) {
                    my @res = &$code;

                    $t->send($stat);

                    return @res;
                }

                my $res = &$code;

                $t->send($stat);

                return $res;
            };
        }

        return @unhandled;
    }
}

sub inc {
    my ( $name, $sample ) = @_;

    my $sock = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerAddr => $Host,
        PeerPort => $Port,
    ) or return;

    my $metric = "$name:1|c\n";

    $metric .= $name . HOST_SUFFIX . ":1|c\n" if $AlsoAppendHost;

    send $sock, $metric, 0;

    return;
}

sub timing {
    my ( $name, $value, $sample ) = @_;

    my $sock = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerAddr => $Host,
        PeerPort => $Port,
    ) or return;

    $value = int $value;

    my $metric = "$name:$value|ms\n";

    $metric .= $name . HOST_SUFFIX . ":$value|ms\n" if $AlsoAppendHost;

    send $sock, $metric, 0;

    return;
}

package StatsD::XS::Timer;

sub reset {
    ${ +shift } = Time::HiRes::time;
}

1;
