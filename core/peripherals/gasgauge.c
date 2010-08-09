#include "gasgauge.h"
#include "hardware_conf.h"
#include "utils/macros.h"
#include "i2c.h"
#include "debug/trace.h"

int gasgauge_init () {
    i2cMasterConf(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_OPmode<<10)|(I2CGG_REG_OPmode), I2CMASTER_WRITE);
    i2cWriteByte(I2CGG_POR_BITMASK|I2CGG_SHELF_BITMASK);
    i2cMasterConf(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_OPmode<<10)|(I2CGG_REG_OPmode), I2CMASTER_WRITE);
    i2cWriteByte(I2CGG_SHELF_BITMASK);
}

int gasgauge_get_stats (gasgauge_stats *stats) {
    uint16_t t;
    uint8_t b;

    TRACE_INFO("gasgauge_stats\r\n");
    i2c_open();

    b = i2cMasterRead(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_VPres<<10)|(I2CGG_REG_VPres));
    t = (uint16_t)b;
    b = i2cMasterRead(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_VPres<<10)|(I2CGG_REG_VPres+1));
    t |= (((uint16_t)b)<<8);

    stats->voltage = ((t>>6)*199)/10;


    b = i2cMasterRead(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_Ires<<10)|(I2CGG_REG_Ires));
    t = (uint16_t)b;
    b = i2cMasterRead(I2CGG_PHY_ADDR, 2, (I2CGG_BANK_Ires<<10)|(I2CGG_REG_Ires+1));
    i2c_close();
    t |= (((uint16_t)b)<<8);

    if (t&0x8000)
        stats->current = -(((int32_t)(t&0x7fff)*157)/10000);//mAmps
    else
        stats->current = ((int32_t)(t&0x7fff)*157)/10000;//mAmps

    TRACE_INFO("gasgauge U: %d I: %d", stats->voltage, stats->current);

    if (ISCLEARED(AT91C_BASE_PIOA->PIO_PDSR, PIN_CHARGING)) {
        TRACE_INFO("Charging.\n\r");
        stats->state = GASGAUGE_STATE_CHARGING;
    } else {
        if (ISCLEARED(AT91C_BASE_PIOA->PIO_PDSR, PIN_CHARGEDONE))
        {
            TRACE_INFO("Charged.\n\r");
            //chargedone=1;
            AT91C_BASE_PIOA->PIO_SODR = CHARGEEN_PIN; //disable
            stats->state = GASGAUGE_STATE_CHARGED;
        } else {

            TRACE_INFO("No charge.\n\r");
            stats->state = GASGAUGE_STATE_NO_CHARGE;
        }
    }
    return 0;
}

