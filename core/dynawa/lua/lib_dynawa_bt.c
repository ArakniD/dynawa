#include "lua.h"
#include "lauxlib.h"
#include "debug/trace.h"
#include "types.h"
#include "lib_dynawa_bt.h"

bt_lua_socket *bt_socket_new(void) {
    bt_lua_socket *sock = (bt_lua_socket*)malloc(sizeof(bt_lua_socket));
    if (sock) {
        memset(sock, 0, sizeof(bt_lua_socket));
    }
    return sock;
}

static int l_cmd (lua_State *L) {
    uint16_t cmd = luaL_checkint(L, 1);

    TRACE_LUA("dynawa.bt.cmd(%d)\r\n", cmd);
    TRACE_INFO("dynawa.bt.cmd(%d)\r\n", cmd);

    switch(cmd) {
    case 1:         // OPEN
        bt_open();
        break;
    case 2:         // CLOSE
        bt_close();
        break;
    case 3:         // SET_LINK_KEY
        {
            const uint8_t *bdaddr = luaL_checkstring(L, 2);
            const uint8_t *link_key = luaL_checkstring(L, 3);

            bt_set_link_key(bdaddr, link_key);
        }
        break;
    case 4:
        bt_inquiry();
        break;
    case 100:       // SOCKET_NEW
        {
            lua_pushvalue(L, 2);
            uint32_t ref_lua_socket = luaL_ref(L, LUA_REGISTRYINDEX);

            bt_lua_socket *sock = bt_socket_new();
            if (sock == NULL) {
                panic();
            }

            sock->ref_lua_socket = ref_lua_socket;
            TRACE_INFO("ref_sock %x\r\n", sock->ref_lua_socket);
            lua_pushlightuserdata(L, (void *)sock);
            return 1;
        }
        break;
    case 101:       // SOCKET_CLOSE
        {
            luaL_checktype(L, 2, LUA_TLIGHTUSERDATA); 
            bt_lua_socket *sock = lua_touserdata(L, 2);

            luaL_unref(L, LUA_REGISTRYINDEX, sock->ref_lua_socket);

            free(sock);
        }
        break;
    case 102:       // SOCKET_BIND
        {
            luaL_checktype(L, 3, LUA_TLIGHTUSERDATA); 
            bt_lua_socket *sock = lua_touserdata(L, 3);

            lua_pushvalue(L, 2);
            uint32_t ref_lua_socket = luaL_ref(L, LUA_REGISTRYINDEX);

            sock->ref_lua_socket = ref_lua_socket;
            TRACE_INFO("ref_sock %x\r\n", sock->ref_lua_socket);
        }
        break;
    case 200:       // FIND_SERVICE
        {
            luaL_checktype(L, 2, LUA_TLIGHTUSERDATA); 
            bt_lua_socket *sock = (bt_lua_socket*)lua_touserdata(L, 2);

            const uint8_t *bdaddr = luaL_checkstring(L, 3);

            bt_find_service((bt_socket*)sock, bdaddr);
        }
        break;
    case 300:       // LISTEN
        {
            luaL_checktype(L, 2, LUA_TLIGHTUSERDATA); 
            bt_lua_socket *sock = (bt_lua_socket*)lua_touserdata(L, 2);

            uint8_t channel = luaL_checkint(L, 3);

            bt_rfcomm_listen((bt_socket*)sock, channel);
        }
        break;
    case 301:       // CONNECT
        {
            luaL_checktype(L, 2, LUA_TLIGHTUSERDATA); 
            bt_lua_socket *sock = (bt_lua_socket*)lua_touserdata(L, 2);

            const uint8_t *bdaddr = luaL_checkstring(L, 3);

            uint8_t channel = luaL_checkint(L, 4);

            bt_rfcomm_connect((bt_socket*)sock, bdaddr, channel);
        }
        break;
    case 400:       // SEND
        {
            luaL_checktype(L, 2, LUA_TLIGHTUSERDATA); 
            bt_lua_socket *sock = (bt_lua_socket*)lua_touserdata(L, 2);

            /*
            luaL_checktype(L, 3, LUA_TLIGHTUSERDATA); 
            void *handle = lua_touserdata(L, 3);
            */

            size_t len;
            const char *data = luaL_checklstring(L, 3, &len);

            TRACE_INFO("data %s %d\r\n", data, len);

            bt_rfcomm_send((bt_socket*)sock, data, len);
        }
        break;
    }
    return 0;
}

static const struct luaL_reg bt [] = {
    {"cmd", l_cmd},
    {NULL, NULL}  /* sentinel */
};

int dynawa_bt_register (lua_State *L) {
    luaL_register(L, NULL, bt);
    return 1;
}
