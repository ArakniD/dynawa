#include <stdio.h>
#include <stdlib.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "trace.h"
#include "led.h"

//#include <utils/macros.h>
#include <peripherals/spi.h>
#include <sdcard/sdcard.h>
//#include <fat/fat.h>
#include <ff.h>
#include "event.h"

static FATFS fatfs;
static FILINFO fileInfo;

int lua_event_loop (void) {

    Io led;
    Led_init(&led);
    Led_setState(&led, 0);

    int error;

    FRESULT f;

    if ((f = disk_initialize (0)) != FR_OK) {
        f_printerror (f);
        TRACE_ERROR("disk_initialize\r\n");
        return 1;
    }
    if ((f = f_mount (0, &fatfs)) != FR_OK) {
        f_printerror (f);
        TRACE_ERROR("f_mount\r\n");
        return 1;
    }

    TRACE_LUA("luaL_newstate\r\n");
    lua_State *L = luaL_newstate();
    TRACE_LUA("done\r\n");
    if (L == NULL) {
        TRACE_ERROR("Err: luaL_newstate()\r\n");
        return 1;
    }
    TRACE_LUA("luaL_openlibs\r\n");
    luaL_openlibs(L);
    luaopen_dynawa(L);

    TRACE_LUA("done\r\n");

    unsigned long ticks = xTaskGetTickCount();

    if (luaL_loadfile(L, "_sys/boot.lua") || lua_pcall(L, 0, 0, 0)) {
        TRACE_ERROR("lua: %s\r\n", lua_tostring(L, -1));
        lua_pop(L, 1);
        lua_close(L);
        panic();
    }

    ticks = xTaskGetTickCount() - ticks;
    TRACE_LUA("initialized %d\r\n", ticks);

    //fflush(stdout);
    while(1) {
        event ev;
        event_get(&ev, EVENT_WAIT_FOREVER);
/*
        ev.type = EVENT_BUTTON_DOWN;
        ev.data.button.id = 1;
*/

/*
        int i;
        for(i = 0; i < sizeof(event); i++) {
            TRACE_LUA("ev[%d]=%d\r\n", i, *(((uint8_t*)&ev) + i));
        }
*/

        lua_getglobal(L, "handle_event");

        switch(ev.type) {
        case EVENT_BUTTON_DOWN:
            TRACE_LUA("button %d down\r\n", ev.data.button.id);
            lua_newtable(L);

            lua_pushstring(L, "type");
            lua_pushstring(L, "button_down");
            lua_settable(L, -3);

            lua_pushstring(L, "button");
            lua_pushnumber(L, ev.data.button.id);
            lua_settable(L, -3);
            break;
        case EVENT_BUTTON_HOLD:
            TRACE_LUA("button %d hold\r\n", ev.data.button.id);
            lua_newtable(L);

            lua_pushstring(L, "type");
            lua_pushstring(L, "button_hold");
            lua_settable(L, -3);

            lua_pushstring(L, "button");
            lua_pushnumber(L, ev.data.button.id);
            lua_settable(L, -3);
/*
rtc_open();
TRACE_INFO("time: %d\r\n", rtc_get_epoch_seconds(NULL));
rtc_close();
*/
            break;
        case EVENT_BUTTON_UP:
            TRACE_LUA("button %d up\r\n", ev.data.button.id);
            lua_newtable(L);

            lua_pushstring(L, "type");
            lua_pushstring(L, "button_up");
            lua_settable(L, -3);

            lua_pushstring(L, "button");
            lua_pushnumber(L, ev.data.button.id);
            lua_settable(L, -3);
            break;
        case EVENT_TIMER:
            TRACE_LUA("timer %x expired\r\n", ev.data.timer.handle);
            lua_newtable(L);

            lua_pushstring(L, "type");
            lua_pushstring(L, "timer_fired");
            lua_settable(L, -3);

            lua_pushstring(L, "handle");
            lua_pushlightuserdata(L, (void*)ev.data.timer.handle);
            lua_settable(L, -3);
            break;
        case EVENT_BT_STOPPED:
            TRACE_LUA("bt stopped\r\n");
            lua_newtable(L);

            lua_pushstring(L, "type");
            lua_pushstring(L, "bt_stopped");
            lua_settable(L, -3);
            break;
        default:
            TRACE_ERROR("Uknown event %x\r\n", ev.type);
        }

        Led_setState(&led, 1);
        unsigned long ticks = xTaskGetTickCount();

        //if (lua_pcall(L, #in, #out, err handler) != 0)
        error = lua_pcall(L, 1, 0, 0);
/*
        lua_call(L, 1, 0);
        error = 0;
*/

        Led_setState(&led, 0);
        ticks = xTaskGetTickCount() - ticks;
        TRACE_LUA("error %d %d\r\n", error, ticks);

        if (error) {
            TRACE_ERROR("lua: %s", lua_tostring(L, -1));
            lua_pop(L, 1);
            panic();
        }
        //fflush(stdout);
    }
    lua_close(L);
    return 0;  
}


char *my_gets (char *buff, int len) {
  
  char b[256];
  int p = 0;
  while(1) {
    int n = read(0, b, 256);

    if (n) {
      int i;
      for(i = 0; i < n; i++) {
        char c = b[i];
        TRACE_LUA("chr %d\r\n", c);
        buff[p++] = c; 
        if (c == '\r') {
          buff[p] = 0;
          return buff;
        }
      }
    }
  }
  return NULL;
}

int lua_main (void) {

  Io led;
  Led_init(&led);
  char buff[256];

  int fimage;
  uint32_t image_size;

/*
  void *x = malloc(10000000);
  TRACE_LUA("malloc %x\r\n", x);
  if (x) free(x);

  fprintf(stdout, "test %d\r\n", 1);
  gets(buff);
*/

  int error;

/*
  spi_init();
  Task_sleep(200);
  if ( sd_init() != SD_OK ) {
    TRACE_ERROR("SD card init failed!\r\n");
  }
*/

/*
  fat_init();

  fimage = fat_open("main.bin",_O_RDONLY);
  if (fimage!=-1)
  {
    image_size = fat_size(fimage);
    TRACE_LUA("main.bin:%dkB\n\r",image_size/1024);
  }
*/

  {
  FRESULT f;

  if ((f = disk_initialize (0)) != FR_OK) {
    f_printerror (f);
    TRACE_ERROR("disk_initialize\r\n");
  } else {
    ULONG p2;
    FATFS *fs;
    int res;
    DIR dir;
    f_mount (0, &fatfs);
/*
    if ((res = f_getfree ("", (ULONG *) &p2, &fs)))
    {
      TRACE_ERROR("f_getfree %d %s\r\n", res, f_ferrorlookup (res));
      f_printerror (res);
    } else {
      TRACE_LUA ("FAT type = %u\nBytes/Cluster = %u\nNumber of FATs = %u\n"
      "Root DIR entries = %u\nSectors/FAT = %u\nNumber of clusters = %u\n"
      "FAT start (lba) = %u\nDIR start (lba,clustor) = %u\nData start (lba) = %u\n",
      fs->fs_type, fs->sects_clust * 512, fs->n_fats,
      fs->n_rootdir, fs->sects_fat, fs->max_clust - 2,
      fs->fatbase, fs->dirbase, fs->database
      );
    }
*/
    if ((res = f_opendir (&dir, ""))) {
      TRACE_ERROR("f_opendir %d %s\r\n", res, f_ferrorlookup (res));
    } else {
  ULONG size;
  USHORT files;
  USHORT dirs;
  for (size = files = dirs = 0;;)
  {
    if (((res = f_readdir (&dir, &fileInfo)) != FR_OK) || !fileInfo.fname [0])
      break;

    if (fileInfo.fattrib & AM_DIR)
      dirs++;
    else
    {
      files++;
      size += fileInfo.fsize;
    }

    printf ("\n%c%c%c%c%c %u/%02u/%02u %02u:%02u %9u  %s",
        (fileInfo.fattrib & AM_DIR) ? 'D' : '-',
        (fileInfo.fattrib & AM_RDO) ? 'R' : '-',
        (fileInfo.fattrib & AM_HID) ? 'H' : '-',
        (fileInfo.fattrib & AM_SYS) ? 'S' : '-',
        (fileInfo.fattrib & AM_ARC) ? 'A' : '-',
        (fileInfo.fdate >> 9) + 1980, (fileInfo.fdate >> 5) & 15, fileInfo.fdate & 31,
        (fileInfo.ftime >> 11), (fileInfo.ftime >> 5) & 63,
        fileInfo.fsize, &(fileInfo.fname [0]));
  }

  TRACE_LUA ("\n%4u File(s),%10u bytes\n%4u Dir(s)", files, size, dirs);
    }
  }
  }
  TRACE_LUA("luaL_newstate\r\n");
  lua_State *L = luaL_newstate();
  TRACE_LUA("done\r\n");
  if (L == NULL) {
    TRACE_ERROR("Err: luaL_newstate()\r\n");
    return 1;
  }
  TRACE_LUA("luaL_openlibs\r\n");
  luaL_openlibs(L);

  TRACE_LUA("done\r\n");

  fflush(stdout);
  //while(read(0, buff, 10)) {
  //while(fgets(buff, sizeof(buff), stdin) != NULL) {
  //while(fgets(buff, sizeof(buff), stdin) != NULL) {
  while(my_gets(buff, sizeof(buff)) != NULL) {
    unsigned int ticks;
    TRACE_LUA("line <%s>\r\n", buff);

    Led_setState(&led, 1);
    ticks = xTaskGetTickCount();
    error = luaL_loadbuffer(L, buff, strlen(buff), "line") || lua_pcall(L, 0, 0, 0);
    ticks = xTaskGetTickCount() - ticks;
    Led_setState(&led, 0);
    TRACE_LUA("error %d %d\r\n", error, ticks);
    if (error) {
      fprintf(stderr, "%s", lua_tostring(L, -1));
      lua_pop(L, 1);
    }
    fflush(stdout);

    TRACE_LUA("fgets %s\r\n", buff);
  }
  lua_close(L);
  return 0;  
}



