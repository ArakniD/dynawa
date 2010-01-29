#include "rtc.h"
#include "i2c.h"

#include "FreeRTOS.h"
#include "hardware_conf.h"
#include "debug/trace.h"
#include <time.h>

#define BCD2BIN(b) ((((b) & 0xf0) >> 4) * 10 + ((b) & 0x0f))
#define BIN2BCD(b) ((((b) / 10) << 4) | ((b) % 10))

int rtc_open() {
    i2c_open();
}

int rtc_close() {
    i2c_close();
}

int rtc_write(struct tm *new_time) {
    TRACE_INFO("rtc_write()\r\n");

    // rtc_wake();
    portENTER_CRITICAL ();

    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGSEC, I2CMASTER_WRITE);
    i2cWriteByte(I2CRTC_STOPBIT);

    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGSEC, I2CMASTER_WRITE);
    i2cWriteByte(0x1);
    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGMIN, I2CMASTER_WRITE);
    i2cWriteByte(0x1);
    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGHR, I2CMASTER_WRITE);
    i2cWriteByte(0x15);

    portEXIT_CRITICAL ();
    // rtc_sleep();
}

int rtc_read(struct tm *curr_time, unsigned int *milliseconds) {
    TRACE_INFO("rtc_read()\r\n");

    // rtc_wake();
    portENTER_CRITICAL ();

    if (milliseconds) {
        *milliseconds = 0;
    }

    /*
       i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGSEC, I2CMASTER_READ);
       int rtcsec = i2cReadByte();

       i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGMIN, I2CMASTER_READ);
       int rtcmin = i2cReadByte();

       i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGHR, I2CMASTER_READ);
       int rtchour = i2cReadByte();
       */
    uint8_t b = i2cMasterRead(I2CRTC_PHY_ADDR, 1, I2CRTC_REGSEC);
    curr_time->tm_sec = BCD2BIN(b & 0x7f);
    b = i2cMasterRead(I2CRTC_PHY_ADDR, 1, I2CRTC_REGMIN);
    curr_time->tm_min = BCD2BIN(b & 0x7f);
    b = i2cMasterRead(I2CRTC_PHY_ADDR, 1, I2CRTC_REGHR);
    curr_time->tm_hour = BCD2BIN(b & 0x3f);
    b = i2cMasterRead(I2CRTC_PHY_ADDR, 1, I2CRTC_REGDATE);
    curr_time->tm_mday = BCD2BIN(b & 0x3f);
    b = i2cMasterRead(I2CRTC_PHY_ADDR, 1, I2CRTC_REGCENMON);
    uint8_t century = (b & 0xc0) >> 6;
/*
century:
0 0 2000 (leap year; (y % 4 == 0) && ((y % 100 != 0) || (y % 400 == 0))
0 1 2100
1 0 2200
1 1 2300
*/

    curr_time->tm_mon = BCD2BIN(b & 0x1f) - 1;
    b = i2cMasterRead(I2CRTC_PHY_ADDR, 1, I2CRTC_REGYEAR);
    curr_time->tm_year = 2000 + century * 100 + BCD2BIN(b) - 1900;
    //curr_time->tm_wday = i2cMasterRead(I2CRTC_PHY_ADDR, 1, I2CRTC_REGDAY);
    //curr_time->tm_yday = i2cMasterRead(I2CRTC_PHY_ADDR, 1, I2CRTC_REGx);
    curr_time->tm_isdst = 0;

    portEXIT_CRITICAL ();
    // rtc_sleep();

    TRACE_INFO("rtc: %02d:%02d:%02d\r\n", curr_time->tm_hour, curr_time->tm_min, curr_time->tm_sec);
}

time_t rtc_get_epoch_seconds (unsigned int *milliseconds) {
  struct tm tm;

  rtc_read (&tm, milliseconds);
  return mktime (&tm);
}

void rtc_set_epoch_seconds (time_t now) {
  struct tm tm;

  localtime_r (&now, &tm);
  rtc_write (&tm);
}

int rtc_set_alarm (struct tm *tm)
{
    if (tm && (mktime (tm) < time (NULL)))
        return -1;

    return 0;
}

struct tm *rtc_get_alarm (struct tm *tm) {
}

time_t rtc_get_alarm_epoch_seconds (void) {
    struct tm tm;

    return mktime (rtc_get_alarm (&tm));
}

int rtc_periodic_alarm (int mode) {
    return 0;
}
