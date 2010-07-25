#include "lua.h"
#include "lauxlib.h"
#include "analogin.h"
#include "debug/trace.h"

static int l_adc (lua_State *L) {

    uint32_t ch = luaL_checkint(L, 1);

    TRACE_LUA("dynawa.x.adc(%d)\r\n", ch);

    AnalogIn adc;
    AnalogIn_init(&adc, ch);
    int value = AnalogIn_value(&adc);
    //int value = AnalogIn_valueWait(&adc);
    AnalogIn_close(&adc);

    lua_pushnumber(L, value);
    return 1;
}

static int l_display_power (lua_State *L) {

    uint32_t state = luaL_checkint(L, 1);

    TRACE_LUA("dynawa.x.display_power(%d)\r\n", state);

    int result = display_power(state);

    lua_pushnumber(L, result);
    return 1;
}

static int l_display_brightness (lua_State *L) {

    uint32_t level = luaL_checkint(L, 1);

    TRACE_LUA("dynawa.x.display_brightness(%d)\r\n", level);

    int result = display_brightness(level);

    lua_pushnumber(L, result);
    return 1;
}

static const struct luaL_reg x [] = {
    {"adc", l_adc},
    {"display_power", l_display_power},
    {"display_brightness", l_display_brightness},
    {NULL, NULL}  /* sentinel */
};

int dynawa_x_register (lua_State *L) {
    luaL_register(L, NULL, x);
    return 1;
}
