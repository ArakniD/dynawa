#ifndef BT_EVENT_H__
#define BT_EVENT_H__

#include "bt_socket.h"

#define EVENT_BT_STARTED                1
#define EVENT_BT_STOPPED                5  
#define EVENT_BT_LINK_KEY_NOT           10
#define EVENT_BT_LINK_KEY_REQ           11
#define EVENT_BT_RFCOMM_CONNECTED       15
#define EVENT_BT_RFCOMM_DISCONNECTED    16
#define EVENT_BT_DATA                   20
#define EVENT_BT_FIND_SERVICE_RES       30
#define EVENT_BT_COMMAND_COMPLETE       100

#define BT_SOCKET_STATE_L2CAP_CONNECTING        1
#define BT_SOCKET_STATE_RFCOMM_CONNECTING       2
#define BT_SOCKET_STATE_RFCOMM_CONNECTED        3

#define BT_SOCKET_ERROR_L2CAP_CANNOT_CONNECT    1
#define BT_SOCKET_ERROR_RFCOMM_CANNOT_CONNECT   2

typedef union {
    void *ptr;
    struct {
        uint8_t cn;
    } service;
    uint16_t error;
} bt_param;

typedef struct {
    uint8_t type;
    bt_socket *sock;
    bt_param param;
} bt_event;

#endif /* BT_EVENT_H__ */