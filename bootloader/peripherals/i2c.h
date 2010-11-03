/* ========================================================================== */
/*                                                                            */
/*   i2c.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */



#ifndef I2C_H_
#define I2C_H_

#define I2CMASTER_WRITE 0
#define I2CMASTER_READ 1

void i2cMasterConf(uint8_t i2c_addr, uint8_t intaddr_size, uint32_t int_addr, uint8_t read);

void i2cWriteByte(uint8_t data);

uint8_t i2cReadByte(void);

void i2cMultipleReadByteStart(void);
uint8_t i2cMultipleReadByteRead(void);
uint8_t i2cMultipleReadByteEnd(void);

void i2cMultipleWriteByteInit(void);
void i2cMultipleWriteByte(uint8_t data);
void i2cMultipleWriteEnd(void);

#endif
