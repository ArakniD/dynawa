#include "lua.h"
#include "lauxlib.h"
#include "debug/trace.h"
#include "types.h"
#include "ff.h"

static int l_mkdir (lua_State *L) {
    const char *path = luaL_checkstring(L, 1);

    TRACE_LUA("dynawa.file.mkdir(%s)\r\n", path);

    if (mkdir(path, 0)) {
        //if (errno == EEXIST)
        lua_pushboolean(L, false);
        /* else
           lua_error("mkdir");
           */
    } else {
        lua_pushboolean(L, true);
    }
    return 1;
}

static int l_dir_stat (lua_State *L) {

    const char *path = luaL_checkstring(L, 1);

    TRACE_LUA("dynawa.file.dir_stat(%s)\r\n", path);

    int res;
    DIR dir;
    if ((res = f_opendir (&dir, ""))) {
        TRACE_ERROR("f_opendir %d %s\r\n", res, f_ferrorlookup (res));
        lua_error("f_opendir");
        lua_pushnil(L); 
    } else {
        lua_newtable(L);
        while(true) {
            FILINFO file_info;
            if (((res = f_readdir (&dir, &file_info)) != FR_OK) || !file_info.fname [0])
                break;

//MV TODO: unicode support (16b)
            char *fname = (file_info.lfname && file_info.lfname [0]) ? file_info.lfname : file_info.fname;
            TRACE_LUA("dir entry %s\r\n", fname);
            lua_pushstring(L, fname);
            if (file_info.fattrib & AM_DIR) {
                lua_pushstring(L, "dir");
            } else {
                lua_pushnumber(L, file_info.fsize);
            }
            lua_settable(L, -3);
        }
    }


    return 1;
}

static const struct luaL_reg file [] = {
    {"mkdir", l_mkdir},
    {"dir_stat", l_dir_stat},
    {NULL, NULL}  /* sentinel */
};

int dynawa_file_register (lua_State *L) {
    luaL_register(L, NULL, file);
    return 1;
}
