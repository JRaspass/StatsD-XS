use ExtUtils::MakeMaker;

# Test if we need to supply librt.
open my $fh, '|-', qw(cc -xc -o/dev/null -);
print $fh "#include <time.h>\nvoid main(void){struct timespec ts;clock_gettime(CLOCK_MONOTONIC,&ts);}";
my $clock_gettime_defined = close $fh;

WriteMakefile(
    LIBS         => [ $clock_gettime_defined ? () : '-lrt' ],
    NAME         => 'StatsD::XS',
    VERSION_FROM => 'lib/StatsD/XS.pm',
);
