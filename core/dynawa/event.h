#ifndef EVENT_H
#define EVENT_H

#include <FreeRTOS.h>
#include <stdint.h>
#include <inttypes.h>
#include <button_event.h>
#include <timer_event.h>
#include <bt_event.h>

#define EVENT_WAIT_FOREVER  portMAX_DELAY

#define EVENT_BUTTON        1
#define EVENT_TIMER         2   
#define EVENT_BT            3   

typedef struct {
    uint32_t type;
    union {
        event_data_button button;
        event_data_timer timer;
        bt_event bt;
    } data;
} event;

#endif // EVENT_H
