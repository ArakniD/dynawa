#include "lua.h"
#include "lauxlib.h"
#include "debug/trace.h"
#include "types.h"

static int l_cmd (lua_State *L) {
    uint16_t cmd = luaL_checkint(L, 1);

    TRACE_LUA("dynawa.bt.cmd(%d)\r\n", cmd);

    switch(cmd) {
    case 1:
        bt_open();
        break;
    case 2:
        bt_close();
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
