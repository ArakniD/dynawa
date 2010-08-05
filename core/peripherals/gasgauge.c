#include "gasgauge.h"
#include "i2c.h"
#include "debug/trace.h"

int gasgauge_init () {
    i2cMasterConf(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_OPmode<<10)|(I2CGG_REG_OPmode), I2CMASTER_WRITE);
    i2cWriteByte(I2CGG_POR_BITMASK|I2CGG_SHELF_BITMASK);
    i2cMasterConf(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_OPmode<<10)|(I2CGG_REG_OPmode), I2CMASTER_WRITE);
    i2cWriteByte(I2CGG_SHELF_BITMASK);
}

int gasgauge_voltage () {
    uint16_t t;
    uint8_t b;

    //TRACE_INFO("gasgauge_voltage\r\n");
    i2c_open();
/*
    i2cMasterConf(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_VPres<<10)|(I2CGG_REG_VPres), I2CMASTER_READ);
    b=i2cReadByte();
*/
    b = i2cMasterRead(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_VPres<<10)|(I2CGG_REG_VPres));
    t = (uint16_t)b;
/*
    i2cMasterConf(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_VPres<<10)|(I2CGG_REG_VPres+1), I2CMASTER_READ);
    b=i2cReadByte();
*/
    b = i2cMasterRead(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_VPres<<10)|(I2CGG_REG_VPres+1));
    i2c_close();
    t |= (((uint16_t)b)<<8);
    
    int packVoltage = ((t>>6)*199)/10;

    TRACE_INFO("gasgauge_voltage %d\r\n", packVoltage);

    return packVoltage;
}

