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
#include "FreeRTOS.h"
#include "semphr.h"
#include "i2c.h"

//temporary test:

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
  pTWI->TWI_CWGR = 0x048080; //I2C clk cca 40kHz 
  //pTWI->TWI_CWGR = 0x049090; //I2C clk cca 40kHz 
  pTWI->TWI_CR = AT91C_TWI_SVDIS; //disable slave
  pTWI->TWI_CR = AT91C_TWI_MSEN; //enable master
}

//write byte - call i2cMasterConf (phy address, int address, r/w)
void i2cWriteByte(uint8_t data)
{  
  volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
  pTWI->TWI_CR = AT91C_TWI_START | AT91C_TWI_STOP;
  pTWI->TWI_THR = data;
  
  while (!((pTWI->TWI_SR)&AT91C_TWI_TXRDY_MASTER));
  //crc:
  //pTWI->TWI_THR = 0xCA;
  //while (!((pTWI->TWI_SR)&AT91C_TWI_TXRDY_MASTER));
  
  while (!((pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER));
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

uint8_t i2cReadByte(void)
{  
  volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
  uint8_t rec;
  uint32_t to;
  //if (stop) pTWI->TWI_CR = AT91C_TWI_STOP; //else pTWI->TWI_CR &= ~(AT91C_TWI_STOP);
  //if (start) pTWI->TWI_CR = AT91C_TWI_START; //else pTWI->TWI_CR &= ~(AT91C_TWI_START);
  pTWI->TWI_CR = AT91C_TWI_START | AT91C_TWI_STOP;
  
  //pTWI->TWI_THR = data;
  to=2000000;
  while ((!((pTWI->TWI_SR)&AT91C_TWI_RXRDY))&&(to));//) { to--; }
  if (!to) TRACE_ALL("I2C error:TWI_RXRDY");
  
  rec = pTWI->TWI_RHR;
  to=2000000;
  while ((!((pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER))&&(to));// { to--; };
  if (!to) TRACE_ALL("I2C error:TWI_TXCOMP_MASTER"); 
  return rec;  
}

void i2cMultipleReadByteStart(void)
{
  volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
  pTWI->TWI_CR = AT91C_TWI_START;
  
  //pTWI->TWI_THR = data;
  while (!((pTWI->TWI_SR)&AT91C_TWI_RXRDY));  
}


uint8_t i2cMultipleReadByteRead(void)
{
  volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
  uint8_t rec;
  while (!((pTWI->TWI_SR)&AT91C_TWI_RXRDY));
  rec = pTWI->TWI_RHR;
  return rec;
}

uint8_t i2cMultipleReadByteEnd(void)
{
  volatile AT91PS_TWI pTWI = AT91C_BASE_TWI;
  pTWI->TWI_CR = AT91C_TWI_STOP;
  uint8_t rec;
  while (!((pTWI->TWI_SR)&AT91C_TWI_RXRDY));
  rec = pTWI->TWI_RHR;
  while (!((pTWI->TWI_SR)&AT91C_TWI_TXCOMP_MASTER));
  return rec;
}

// MV

// TODO: add mutex
static unsigned int i2c_open_count = 0;
static xSemaphoreHandle i2c_mutex;

int i2c_init() {
    i2c_mutex = xSemaphoreCreateMutex();
    if(i2c_mutex == NULL)
        panic();
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

void i2cMasterWrite(uint8_t i2c_addr, uint8_t intaddr_size, uint32_t int_addr, uint8_t data) {
    xSemaphoreTake(i2c_mutex, -1); 
    i2cMasterConf(i2c_addr, intaddr_size, int_addr, I2CMASTER_WRITE);
    i2cWriteByte(data);
    xSemaphoreGive(i2c_mutex); 
}

uint8_t i2cMasterRead(uint8_t i2c_addr, uint8_t intaddr_size, uint32_t int_addr) {
    xSemaphoreTake(i2c_mutex, -1); 
    i2cMasterConf(i2c_addr, intaddr_size, int_addr, I2CMASTER_READ);
    uint8_t data = i2cReadByte();
    xSemaphoreGive(i2c_mutex); 
    return data;
}
