#ifndef BT_SOCKET_H_
#define BT_SOCKET_H_

#define BT_SOCKET_STATE_INITIALIZED     1
#define BT_SOCKET_STATE_CONNECTING      2
#define BT_SOCKET_STATE_CONNECTED       3
//#define BT_SOCKET_STATE_DISCONNECTING 4
#define BT_SOCKET_STATE_DISCONNECTED    5

#define BT_SOCKET_ERR_OK                1

typedef struct {
    uint8_t proto;
    uint16_t state;
    uint8_t current_cmd;
    void *pcb;
    uint8_t cn;
} bt_socket;

#endif /* BT_SOCKET_H_ */