#ifndef BUTTONS_H
#define BUTTONS_H

#include "io.h"
#include "timer.h"

#define NUM_BUTTONS     5

typedef struct {
    Io io;
    bool down;
    bool held;
    Timer timer;
    bool timer_started;
} Button;

#endif // BUTTONS_H
