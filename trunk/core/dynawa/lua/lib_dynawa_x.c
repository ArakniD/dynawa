#include "lua.h"
#include "lauxlib.h"
#include "analogin.h"
#include "debug/trace.h"

static int l_adc (lua_State *L) {

    uint32_t ch = luaL_checkint(L, 1);

    TRACE_LUA("dynawa.x.amblightsensor(%d)\r\n", ch);

    AnalogIn adc;
    AnalogIn_init(&adc, ch);
    //int value = AnalogIn_value(&adc);
    int value = AnalogIn_valueWait(&adc);
    AnalogIn_close(&adc);

    lua_pushnumber(L, value);
    return 1;
}

static const struct luaL_reg x [] = {
    {"adc", l_adc},
    {NULL, NULL}  /* sentinel */
};

int dynawa_x_register (lua_State *L) {
    luaL_register(L, NULL, x);
    return 1;
}
