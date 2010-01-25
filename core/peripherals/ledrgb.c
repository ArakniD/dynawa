#include "ledrgb.h"
#include "i2c.h"

void ledrgb_set(uint8_t rgb)
{
    /*
       if (rgb&0x1) i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_RPWM, 0xff);
       if (rgb&0x2) i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_GPWM, 0xff);
       if (rgb&0x4) i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_BPWM, 0xff);    

       i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_GPWM, 0x0);
       i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_BPWM, 0x0); 
    // ?                i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_RCURRENT, 0x15);
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_RPWM, 0xff);
    */

    if (rgb & 0x1) {
        i2cMasterConf(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_RPWM, I2CMASTER_WRITE);
        i2cWriteByte(0xff);
    }
    if (rgb & 0x2) {
        i2cMasterConf(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_GPWM, I2CMASTER_WRITE);
        i2cWriteByte(0xff);
    }
    if (rgb & 0x4) {
        i2cMasterConf(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_BPWM, I2CMASTER_WRITE);
        i2cWriteByte(0xff);
    }
}

int ledrgb_open () {
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_ENABLE, LEDRGB_CHIPEN);
    //delay(50);
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_CONFIG, LEDRGB_CPMODE_AUTO|LEDRGB_PWM_HF|LEDRGB_INT_CLK_EN|LEDRGB_R_TO_BATT);
    //delay(20);
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_OPMODE, LEDRGB_RMODE_DC|LEDRGB_GMODE_DC|LEDRGB_BMODE_DC);
    //config lights:      
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_RCURRENT, 0x20);
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_GCURRENT, 0x20);
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_BCURRENT, 0x20);
}

int ledrgb_close () {
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_CONFIG, 0);
    i2cMasterWrite(LEDRGB_PHY_ADDR, 1, LEDRGB_REG_ENABLE, 0);
}
