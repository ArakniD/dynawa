#include "gasgauge.h"

int gasgauge_init () {
    i2cMasterConf(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_OPmode<<10)|(I2CGG_REG_OPmode), I2CMASTER_WRITE);
    i2cWriteByte(I2CGG_POR_BITMASK|I2CGG_SHELF_BITMASK);
    i2cMasterConf(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_OPmode<<10)|(I2CGG_REG_OPmode), I2CMASTER_WRITE);
    i2cWriteByte(I2CGG_SHELF_BITMASK);
}
