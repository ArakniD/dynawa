#ifndef BT_H__
#define BT_H__

#include "task_param.h"

#define BC_STATE_STOPPED             0
#define BC_STATE_STARTED             10
#define BC_STATE_ANAFREQ_SET         20
#define BC_STATE_BAUDRATE_SET        30
#define BC_STATE_LC_MAX_TX_POWER            50
#define BC_STATE_LC_DEFAULT_TX_POWER        51
#define BC_STATE_LC_MAX_TX_POWER_NO_RSSI    52
#define BC_STATE_RESTARTING          1000
#define BC_STATE_READY               10000

#define BT_COMMAND_STOP     1

#define BT_LED_LOW          0x40
#define BT_LED_HIGH         0xff

typedef struct {
    uint8_t id;
} bt_command;

#endif /* BT_H__ */
