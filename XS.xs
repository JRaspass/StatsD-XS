#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <time.h>

MODULE = StatsD::XS PACKAGE = StatsD::XS

PROTOTYPES: DISABLE

SV *
timer()
    CODE:
        struct timespec ts;

        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);

        AV *av = newAV();

        av_push(av, newSViv(ts.tv_sec));
        av_push(av, newSViv(ts.tv_nsec));

        RETVAL = sv_bless(
            newRV_noinc((SV*)av),
            gv_stashpv("StatsD::XS::Timer", 0)
        );
    OUTPUT:
          RETVAL

MODULE = StatsD::XS PACKAGE = StatsD::XS::Timer

PROTOTYPES: DISABLE

SV *
send(SV *self, SV *name)
    CODE:
        struct timespec ts;

        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);

        AV *start = (AV *)SvRV(self);

        IV sec  = SvIVX(*av_fetch(start, 0, FALSE));
        IV nsec = SvIVX(*av_fetch(start, 1, FALSE));

        uint took = (ts.tv_sec - sec) * 1000 + (ts.tv_nsec - nsec) / 1000000;

        struct sockaddr_in address = {
            AF_INET,
            htons(    SvIV_nomg(      get_sv("StatsD::XS::Port", 0))),
            inet_addr(SvPV_nomg_nolen(get_sv("StatsD::XS::Host", 0))),
        };

        char *name_char = SvPV_nomg_nolen(name);

        int msg_len = snprintf(NULL, 0, "%s:%d|ms\n", name_char, took);

        char *msg = alloca(msg_len);

        sprintf(msg, "%s:%d|ms\n", name_char, took);

        sendto(
            socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP),
            msg,
            msg_len,
            0,
            &address,
            sizeof(struct sockaddr_in)
        );

        RETVAL = SvREFCNT_inc(self);
    OUTPUT:
          RETVAL
