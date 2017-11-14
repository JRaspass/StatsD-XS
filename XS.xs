#define PERL_NO_GET_CONTEXT

#include <EXTERN.h>
#include <XSUB.h>
#include <perl.h>
#include <time.h>

char hostname[64];
HV *pkg;

void send_msg(pTHX_ SV *name, int value, char* type) {
    char *name_char = SvPV_nomg_nolen(name);

    char *msg;
    int msg_len;

    if (SvTRUE_nomg(get_sv("StatsD::XS::AlsoAppendHost", 0))) {
        msg_len = snprintf(
            NULL, 0, "%s:%d|%s\n%s.%s:%d|%s\n",
            name_char,           value, type,
            name_char, hostname, value, type
        );

        msg = alloca(msg_len);

        sprintf(
            msg,  "%s:%d|%s\n%s.%s:%d|%s\n",
            name_char,           value, type,
            name_char, hostname, value, type
        );
    }
    else {
        msg_len = snprintf(NULL, 0, "%s:%d|%s\n", name_char, value, type);

        msg = alloca(msg_len);

        sprintf(msg, "%s:%d|%s\n", name_char, value, type);
    }

    struct sockaddr_in address = {
        AF_INET,
        htons(    SvIV_nomg(      get_sv("StatsD::XS::Port", 0))),
        inet_addr(SvPV_nomg_nolen(get_sv("StatsD::XS::Host", 0))),
    };

    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);

    sendto(
        sock,
        msg,
        msg_len,
        0,
        &address,
        sizeof(struct sockaddr_in)
    );

    close(sock);
}

MODULE = StatsD::XS PACKAGE = StatsD::XS

BOOT:
    gethostname(hostname, sizeof(hostname) - 1);
    pkg = gv_stashpvn("StatsD::XS", 10, 0);

void
gauge(SV *name, SV *value)
    CODE:
        send_msg(aTHX_ name, SvIV_nomg(value), "g");

void
inc(SV *name)
    CODE:
        send_msg(aTHX_ name, 1, "c");

void
reset(SV *self)
    CODE:
        struct timespec ts;

        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);

        SV **start = AvARRAY(SvRV(self));

        SvIV_set(start[0], ts.tv_sec);
        SvIV_set(start[1], ts.tv_nsec);

void
send(SV *self, SV *name)
    CODE:
        struct timespec ts;

        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);

        SV **start = AvARRAY(SvRV(self));

        IV sec  = SvIVX(start[0]);
        IV nsec = SvIVX(start[1]);

        uint took = (ts.tv_sec - sec) * 1000 + (ts.tv_nsec - nsec) / 1000000;

        send_msg(aTHX_ name, took, "ms");

SV *
timer(...)
    CODE:
        struct timespec ts;

        clock_gettime(CLOCK_MONOTONIC_RAW, &ts);

        AV *av = newAV();

        SV **ary;
        Newx(ary, 2, SV*);

        AvALLOC(av) = AvARRAY(av) = ary;
        AvFILLp(av) = AvMAX(av)   = 1;

        ary[0] = newSViv(ts.tv_sec);
        ary[1] = newSViv(ts.tv_nsec);

        RETVAL = sv_bless(newRV_noinc((SV*)av), pkg);
    OUTPUT:
          RETVAL
