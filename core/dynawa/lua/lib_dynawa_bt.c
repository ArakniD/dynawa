#include "lua.h"
#include "lauxlib.h"
#include "debug/trace.h"
#include "types.h"

static int l_cmd (lua_State *L) {
    uint16_t cmd = luaL_checkint(L, 1);

    TRACE_LUA("dynawa.bt.cmd(%d)\r\n", cmd);
    TRACE_INFO("dynawa.bt.cmd(%d)\r\n", cmd);

    switch(cmd) {
    case 1:
        bt_open();
        break;
    case 2:
        bt_close();
        break;
    case 3:
        {
            const uint8_t *bdaddr = luaL_checkstring(L, 2);
            const uint8_t *link_key = luaL_checkstring(L, 3);

            bt_set_link_key(bdaddr, link_key);
        }
        break;
    case 4:
        bt_inquiry();
        break;
    case 5:
        {
            const uint8_t *bdaddr = luaL_checkstring(L, 2);

            bt_sdp_search(bdaddr);
        }
        break;
    case 6:
        {
            const uint8_t *bdaddr = luaL_checkstring(L, 2);
            uint8_t *channel = luaL_checkint(L, 3);

            bt_rfcomm_connect(bdaddr, channel);
        }
        break;
    case 10:
        {
            luaL_checktype(L, 2, LUA_TLIGHTUSERDATA); 
            void *handle = lua_touserdata(L, 2);
            const char *data = luaL_checkstring(L, 3);
            TRACE_INFO("data %s\r\n", data);

            bt_rfcomm_send(handle, data);
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
