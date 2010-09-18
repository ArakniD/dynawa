#include "lua.h"
#include "lauxlib.h"
#include "audio.h"
#include "debug/trace.h"

static int l_play (lua_State *L) {

    TRACE_LUA("dynawa.audio.play()\r\n");

    luaL_checktype(L, 1, LUA_TUSERDATA);
    audio_sample *sample = lua_touserdata(L, 1);

    audio_play(sample, 0, 0);

    return 0;
}

static int l_stop (lua_State *L) {

    TRACE_LUA("dynawa.audio.stop()\r\n");

    audio_stop();

    return 0;
}

static void *lua_malloc(size_t size, void *arg) {
    lua_State *L = (lua_State *)arg;
    return lua_newuserdata(L, size);
}

static int l_sample_from_wav_file (lua_State *L) {

    const char *path = luaL_checkstring(L, 1);

    TRACE_LUA("dynawa.audio.sample_from_wav_file(%s)\r\n", path);

    audio_sample *sample = audio_sample_from_wav_file(path, 0, 0, 0, lua_malloc, L);

    return 1;
}

static const struct luaL_reg audio [] = {
    {"play", l_play},
    {"stop", l_stop},
    {"sample_from_wav_file", l_sample_from_wav_file},
    {NULL, NULL}  /* sentinel */
};

int dynawa_audio_register (lua_State *L) {
    luaL_register(L, NULL, audio);
    return 1;
}
