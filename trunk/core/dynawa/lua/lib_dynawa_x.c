#include "lua.h"
#include "lauxlib.h"
#include "analogin.h"
#include "gasgauge.h"
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

static int l_vibrator_set (lua_State *L) {

    luaL_checktype(L, 1, LUA_TBOOLEAN);
    bool on = lua_toboolean(L, 1);
    //bool on = luaL_checkint(L, 1);

    TRACE_LUA("dynawa.x.vibrator_set(%d)\r\n", on);

    vibrator_set(on);

    return 0;
}

static int l_battery_stats (lua_State *L) {

    TRACE_LUA("dynawa.x.battery_stats()\r\n");

    gasgauge_stats stats;
    //gasgauge_get_stats (&stats);
    battery_get_stats (&stats);

    lua_newtable(L);

    lua_pushstring(L, "state");
    lua_pushnumber(L, stats.state);
    lua_settable(L, -3);

    lua_pushstring(L, "voltage");
    lua_pushnumber(L, stats.voltage);
    lua_settable(L, -3);

    lua_pushstring(L, "current");
    lua_pushnumber(L, stats.current);
    lua_settable(L, -3);

    return 1;
}

static int l_accel_stats (lua_State *L) {

    TRACE_LUA("dynawa.x.accel_stats()\r\n");

    int16_t x = 0, y = 0, z = 0;
    accel_read(&x, &y, &z, true);

    lua_newtable(L);

    lua_pushstring(L, "x");
    lua_pushnumber(L, x);
    lua_settable(L, -3);

    lua_pushstring(L, "y");
    lua_pushnumber(L, y);
    lua_settable(L, -3);

    lua_pushstring(L, "z");
    lua_pushnumber(L, z);
    lua_settable(L, -3);

    return 1;
}

static const struct luaL_reg x [] = {
    {"adc", l_adc},
    {"display_power", l_display_power},
    {"display_brightness", l_display_brightness},
    {"vibrator_set", l_vibrator_set},
    {"battery_stats", l_battery_stats},
    {"accel_stats", l_accel_stats},
    {NULL, NULL}  /* sentinel */
};

int dynawa_x_register (lua_State *L) {
    luaL_register(L, NULL, x);
    return 1;
}
