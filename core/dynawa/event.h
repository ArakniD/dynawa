#ifndef EVENT_H
#define EVENT_H

#include <FreeRTOS.h>
#include <stdint.h>
#include <timer.h>

#define EVENT_WAIT_FOREVER  portMAX_DELAY

#define EVENT_BUTTON_DOWN       1
#define EVENT_BUTTON_HOLD       2
#define EVENT_BUTTON_UP         3
#define EVENT_TIMER             10
#define EVENT_BT_STOPPED        100

typedef struct {
    uint8_t id;
} event_data_button;

typedef struct {
    TimerHandle handle;
} event_data_timer;

typedef struct {
    uint32_t type;
    union {
        event_data_button button;
        event_data_timer timer;
    } data;
} event;

#endif // EVENT_H
