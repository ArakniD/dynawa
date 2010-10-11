/* ========================================================================== */
/*                                                                            */
/*   i2c.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include <stdlib.h>
#include <unistd.h>
//#include <inttypes.h>
#include <hardware_conf.h>
#include <firmware_conf.h>
#include <peripherals/pmc/pmc.h>
#include <debug/trace.h>
#include <utils/time.h>
#include "FreeRTOS.h"
#include "semphr.h"
#include "i2c.h"

//temporary test:

#define I2C_TIMEOUT     100

void i2cMasterConf(uint8_t i2c_addr, uint8_t intaddr_size, uint32_t int_addr, uint8_t read)
{
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
    uint32_t rflag = 0;

    //setup master mode etc...
    pTWI->TWI_CR = AT91C_TWI_SWRST;

    //pTWI->TWI_CR = AT91C_TWI_MSDIS;
    //read status - just for clearance
    //rflag=pTWI->TWI_SR;

    rflag=0;

    if (read) rflag = AT91C_TWI_MREAD; //read/write access

    pTWI->TWI_CR &= ~(AT91C_TWI_SWRST);

    switch (intaddr_size)
    {
        case 0: { pTWI->TWI_MMR = (AT91C_TWI_IADRSZ_NO | (((uint32_t)i2c_addr)<<16) | rflag) ; break; }  
        case 1: { pTWI->TWI_MMR = (AT91C_TWI_IADRSZ_1_BYTE | (((uint32_t)i2c_addr)<<16) | rflag) ; break; }
        case 2: { pTWI->TWI_MMR = (AT91C_TWI_IADRSZ_2_BYTE | (((uint32_t)i2c_addr)<<16) | rflag) ; break; }
        case 3: { pTWI->TWI_MMR = (AT91C_TWI_IADRSZ_3_BYTE | (((uint32_t)i2c_addr)<<16) | rflag) ;break; }
    }
    pTWI->TWI_IADR = int_addr;
    pTWI->TWI_CWGR = 0x048585; //I2C clk cca 9kHz 
    pTWI->TWI_CR = AT91C_TWI_SVDIS; //disable slave
    pTWI->TWI_CR = AT91C_TWI_MSEN; //enable master
}

//write byte - call i2cMasterConf (phy address, int address, r/w)
int i2cWriteByte(uint8_t data)
{  
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
    uint32_t s1,s2;
    //uint32_t tmout = timeval + I2C_TIMEOUT;    // 50ms second timeout
    uint32_t tmout = Timer_tick_count() + I2C_TIMEOUT;    // 50ms second timeout

    pTWI->TWI_CR = AT91C_TWI_START | AT91C_TWI_STOP;
    pTWI->TWI_THR = data;


    //while (!((s1=pTWI->TWI_SR)&AT91C_TWI_TXRDY_MASTER)) if ((s1&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(timeval > tmout)) return;
    while (!((s1=pTWI->TWI_SR)&AT91C_TWI_TXRDY_MASTER)) if ((s1&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(Timer_tick_count() > tmout)) {
        return -1;
    }
    //crc:
    //pTWI->TWI_THR = 0xCA;
    //while (!((pTWI->TWI_SR)&AT91C_TWI_TXRDY_MASTER));

    //while (!((s2=pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER)) if ((s2&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(timeval > tmout)) return;
    while (!((s2=pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER)) if ((s2&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(Timer_tick_count() > tmout)) {
        return -1;
    }
    return 0;
}

void i2cMultipleWriteByteInit(void)
{  
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
    pTWI->TWI_CR = AT91C_TWI_START | AT91C_TWI_STOP;
}

void i2cMultipleWriteByte(uint8_t data) 
{ 
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
    pTWI->TWI_THR = data;

    while (!((pTWI->TWI_SR)&AT91C_TWI_TXRDY_MASTER));
    //crc:
    //pTWI->TWI_THR = 0xCA;
    //while (!((pTWI->TWI_SR)&AT91C_TWI_TXRDY_MASTER));    
}

void i2cMultipleWriteEnd(void)
{ 
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI; 
    while (!((pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER));
}

int i2cReadByte(uint8_t *data)
{  
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
    uint32_t to;
    uint32_t s1,s2;
    //uint32_t tmout = timeval + I2C_TIMEOUT;    // 50ms second timeout
    uint32_t tmout = Timer_tick_count() + I2C_TIMEOUT;    // 50ms second timeout
    //if (stop) pTWI->TWI_CR = AT91C_TWI_STOP; //else pTWI->TWI_CR &= ~(AT91C_TWI_STOP);
    //if (start) pTWI->TWI_CR = AT91C_TWI_START; //else pTWI->TWI_CR &= ~(AT91C_TWI_START);
    pTWI->TWI_CR = AT91C_TWI_START | AT91C_TWI_STOP;

    //pTWI->TWI_THR = data;
    to=500000;
    //while ((!((s1=pTWI->TWI_SR)&AT91C_TWI_RXRDY))) if ((s1&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(timeval > tmout)) return 0;
    while ((!((s1=pTWI->TWI_SR)&AT91C_TWI_RXRDY))) if ((s1&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(Timer_tick_count() > tmout)) {
        return -1;
    }
    //if (!to) TRACE_ALL("I2C error:TWI_RXRDY");

    *data = pTWI->TWI_RHR;
    to=500000;
    //while ((!((s2=pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER)))  if ((s2&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(timeval > tmout)) return 0;
    while ((!((s2=pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER)))  if ((s2&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(Timer_tick_count() > tmout)) {
        panic("i2cReadByte 2");
        return -1;
    }
    //if (!to) TRACE_ALL("I2C error:TWI_TXCOMP_MASTER"); 
    return 0;  
}

void i2cMultipleReadByteStart(void)
{
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
    uint32_t s1,s2;
    //uint32_t tmout = timeval + I2C_TIMEOUT;    // 50ms second timeout
    uint32_t tmout = Timer_tick_count() + I2C_TIMEOUT;    // 50ms second timeout


    pTWI->TWI_CR = AT91C_TWI_START;

    //pTWI->TWI_THR = data;
    //while (!((pTWI->TWI_SR)&AT91C_TWI_RXRDY));  
}


uint8_t i2cMultipleReadByteRead(void)
{
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
    uint8_t rec;
    uint32_t s1,s2;
    //uint32_t tmout = timeval + I2C_TIMEOUT;    // 50ms second timeout
    uint32_t tmout = Timer_tick_count() + I2C_TIMEOUT;    // 50ms second timeout
    //while ((!((s1=pTWI->TWI_SR)&AT91C_TWI_RXRDY))) if ((s1&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(timeval > tmout)) return 0;
    while ((!((s1=pTWI->TWI_SR)&AT91C_TWI_RXRDY))) if ((s1&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(Timer_tick_count() > tmout)) {
        panic("i2cMultipleReadByteRead");
        return 0;
    }
    //if (!to) TRACE_ALL("I2C error:TWI_RXRDY");
    rec = pTWI->TWI_RHR;
    return rec;
}

uint8_t i2cMultipleReadByteEnd(void)
{
    volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
    //uint32_t tmout = timeval + I2C_TIMEOUT;    // 50ms second timeout
    uint32_t tmout = Timer_tick_count() + I2C_TIMEOUT;    // 50ms second timeout
    uint32_t s1,s2;
    pTWI->TWI_CR = AT91C_TWI_STOP;
    uint8_t rec=0;
    //to=500000;
    //while ((!((s1=pTWI->TWI_SR)&AT91C_TWI_RXRDY))) if ((s1&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(timeval > tmout)) return 0;
    while ((!((s1=pTWI->TWI_SR)&AT91C_TWI_RXRDY))) if ((s1&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(Timer_tick_count() > tmout)) {
        panic("i2cMultipleReadByteEnd");
        return 0;
    }
    //if (!to) TRACE_ALL("I2C error:TWI_RXRDY");
    rec = pTWI->TWI_RHR;
    //while ((!((s2=pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER)))  if ((s2&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(timeval > tmout)) return 0;
    while ((!((s2=pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER)))  if ((s2&(AT91C_TWI_NACK_MASTER|AT91C_TWI_OVRE|AT91C_TWI_ARBLST_MULTI_MASTER))||(Timer_tick_count() > tmout)) {
        panic("i2cMultipleReadByteEnd 2");
        return 0;
    }
    return rec;
}


// MV

// TODO: add mutex
static unsigned int i2c_open_count = 0;
static xSemaphoreHandle i2c_mutex;

int i2c_init() {
    i2c_mutex = xSemaphoreCreateMutex();
    if(i2c_mutex == NULL) {
        panic("i2c_init");
    }
    return 0;
}

int i2c_open() {
    xSemaphoreTake(i2c_mutex, -1); 
    if(!i2c_open_count++)
        pPMC->PMC_PCER = ( (uint32_t) 1 << AT91C_ID_TWI );
    xSemaphoreGive(i2c_mutex); 
    return 0;
}

int i2c_close() {
    xSemaphoreTake(i2c_mutex, -1); 
    if(i2c_open_count && --i2c_open_count == 0)
        pPMC->PMC_PCDR = ( (uint32_t) 1 << AT91C_ID_TWI );
    xSemaphoreGive(i2c_mutex); 
    return 0;
}

int i2cMasterWrite(uint8_t i2c_addr, uint8_t intaddr_size, uint32_t int_addr, uint8_t data) {
    xSemaphoreTake(i2c_mutex, -1); 
    i2cMasterConf(i2c_addr, intaddr_size, int_addr, I2CMASTER_WRITE);
    int rc = i2cWriteByte(data);
    xSemaphoreGive(i2c_mutex); 
    return rc;
}

int i2cMasterRead(uint8_t i2c_addr, uint8_t intaddr_size, uint32_t int_addr, uint8_t *data) {
    xSemaphoreTake(i2c_mutex, -1); 
    i2cMasterConf(i2c_addr, intaddr_size, int_addr, I2CMASTER_READ);
    int rc = i2cReadByte(data);
    xSemaphoreGive(i2c_mutex); 
    return rc;
}
