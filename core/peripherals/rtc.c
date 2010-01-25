#include "rtc.h"
#include "i2c.h"

int rtc_set() {
    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGSEC, I2CMASTER_WRITE);
    i2cWriteByte(I2CRTC_STOPBIT);
    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGSEC, I2CMASTER_WRITE);
    i2cWriteByte(0x1);
    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGMIN, I2CMASTER_WRITE);
    i2cWriteByte(0x1);
    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGHR, I2CMASTER_WRITE);
    i2cWriteByte(0x11);
    i2cWriteByte(0x15);
}

int rtc_get() {
    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGSEC, I2CMASTER_READ);
    int rtcsec = i2cReadByte();
      
    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGMIN, I2CMASTER_READ);
    int rtcmin = i2cReadByte();

    i2cMasterConf(I2CRTC_PHY_ADDR, 1, I2CRTC_REGHR, I2CMASTER_READ);
    int rtchour = i2cReadByte();
}
