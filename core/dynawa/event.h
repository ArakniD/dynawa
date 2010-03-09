#ifndef EVENT_H
#define EVENT_H

#include <FreeRTOS.h>
#include <stdint.h>
#include <timer.h>
#include <bt.h>

#define EVENT_WAIT_FOREVER  portMAX_DELAY

#define EVENT_BUTTON_DOWN       1
#define EVENT_BUTTON_HOLD       2
#define EVENT_BUTTON_UP         3
#define EVENT_TIMER             10
#define EVENT_BT_STARTED        100
#define EVENT_BT_STOPPED        101
#define EVENT_BT_LINK_KEY_NOT   110
#define EVENT_BT_LINK_KEY_REQ   111
#define EVENT_BT_RFCOMM_CONNECTED 115
#define EVENT_BT_RFCOMM_DISCONNECTED 116
#define EVENT_BT_DATA           120
#define EVENT_BT_SDP_RES     130

typedef struct {
    uint8_t id;
} event_data_button;

typedef struct {
    TimerHandle handle;
} event_data_timer;

/*
typedef struct {
    bt_event event;
} event_data_bt;
*/

typedef struct {
    uint32_t type;
    union {
        event_data_button button;
        event_data_timer timer;
        bt_event bt;
    } data;
} event;

#endif // EVENT_H
