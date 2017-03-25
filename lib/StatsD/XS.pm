package StatsD::XS 0.001;

use strict;
use warnings;

use B;
use XSLoader;

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

1;
