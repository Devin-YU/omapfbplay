/*
    Copyright (C) 2009 Mans Rullgard

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use, copy,
    modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
 */

#ifndef OFBP_TIMER_H
#define OFBP_TIMER_H

#include <time.h>

#include "util.h"

struct timer {
    const char *name;
    int (*open)(const char *);
    int (*start)(struct timespec *ts);
    int (*read)(struct timespec *ts);
    int (*wait)(struct timespec *ts);
    int (*close)(void);
};

extern const struct timer *ofbp_timer_start[];

#define TIMER(name) DRIVER(timer, name)

unsigned ts_diff_ms(struct timespec *tv1, struct timespec *tv2);
unsigned ts_diff_ns(const struct timespec *ts1, const struct timespec *ts2);
void ts_add_ns(struct timespec *ts, unsigned nsec);
void ts_add(struct timespec *ts, const struct timespec *td);
void ts_sub(struct timespec *ts, const struct timespec *td);

#endif /* OFBP_TIMER_H */
