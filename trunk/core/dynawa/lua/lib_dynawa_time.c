#include "lua.h"
#include "lauxlib.h"
#include "debug/trace.h"

static int l_set (lua_State *L) {
    TRACE_LUA("dynawa.time.set\r\n");

    return 0;
}

static int l_get (lua_State *L) {
    TRACE_LUA("dynawa.time.get\r\n");

    return 1;
}

static int l_milliseconds (lua_State *L) {
    TRACE_LUA("dynawa.time.milliseconds\r\n");

    lua_pushnumber(L, xTaskGetTickCount());
    return 1;
}

static const struct luaL_reg time [] = {
    {"set", l_set},
    {"get", l_get},
    {"milliseconds", l_milliseconds},
    {NULL, NULL}  /* sentinel */
};

int dynawa_time_register (lua_State *L) {
    luaL_register(L, NULL, time);
    return 1;
}
