#include "accel.h"
#include "spi.h"
#include <hardware_conf.h>

int16_t spiAccelRead16(uint8_t reg)
{
    volatile AT91PS_SPI pSPI = AT91C_BASE_SPI;
    int16_t rx=0;
    pSPI->SPI_MR = AT91C_SPI_MSTR | (20 << 24); //CS0

    pSPI->SPI_TDR = (((reg&0x3F) | SPIACCEL_REGMREAD | SPIACCEL_REGREAD )<<8); //CS0:

    while (!((pSPI->SPI_SR)&AT91C_SPI_TDRE));

    rx = (pSPI->SPI_RDR&0xff00); //low bytes
    //rx = (pSPI->SPI_RDR&0xff00)>>8; //low bytes
    pSPI->SPI_CR = AT91C_SPI_LASTXFER;
    pSPI->SPI_TDR=0;
    while (!((pSPI->SPI_SR)&AT91C_SPI_TDRE));

    //rx |= ((pSPI->SPI_RDR&0xff)<<8); //high bytes
    rx |= ((pSPI->SPI_RDR&0xff)); //high bytes
    //rx |= ((pSPI->SPI_RDR&0xff00)); //high bytes
    return rx;
}

void spiAccelWrite8(uint8_t reg, uint8_t data)
{
    volatile AT91PS_SPI pSPI = AT91C_BASE_SPI;

    pSPI->SPI_MR = AT91C_SPI_MSTR | (20 << 24); //CS0
    pSPI->SPI_CR = AT91C_SPI_LASTXFER;
    pSPI->SPI_TDR = (((reg&0x3F))<<8) | (data); //CS0:

    while (!((pSPI->SPI_SR)&AT91C_SPI_TDRE));
}

int accel_start() {
    //switch on:
    spiAccelWrite8(SPIACCEL_CTRL_REG1, 0xC7);
    //spiAccelWrite8(SPIACCEL_CTRL_REG2, 0x40);
    //spiAccelWrite8(SPIACCEL_CTRL_REG3, 0x00);
}

int accel_read(int *x, int *y, int *z) {
    *x = spiAccelRead16(SPIACCEL_REG_XL);
    *y = spiAccelRead16(SPIACCEL_REG_YL);
    *z = spiAccelRead16(SPIACCEL_REG_ZL);

    return 0;
}

