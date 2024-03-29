/*-----------------------------------------------------------------------*/
/* Low level disk I/O module skeleton for FatFs     (C)ChaN, 2007        */
/*-----------------------------------------------------------------------*/
/* This is a stub disk I/O module that acts as front end of the existing */
/* disk I/O modules and attach it to FatFs module with common interface. */
/*-----------------------------------------------------------------------*/

#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "hardware_conf.h"
#include "firmware_conf.h"
#include "board_lowlevel.h"
#include <utils/macros.h>

#include <screen/screen.h>
#include <screen/font.h>
#include <debug/trace.h>
#include <sdcard/sdcard.h>
#include "diskio.h"

/*-----------------------------------------------------------------------*/
/* Correspondence between physical drive number and physical drive.      */
/*-----------------------------------------------------------------------*/

#define ATA		0
#define MMC		1
#define USB		2



DSTATUS disk_initialize (
        BYTE drv                                /* Physical drive nmuber (0..) */
)
{
/* MV
        DSTATUS stat;
        int result;

        switch (drv) {
        case ATA :
                result = ATA_disk_initialize();
                // translate the reslut code here

                return stat;

        case MMC :
                result = MMC_disk_initialize();
                // translate the reslut code here

                return stat;

        case USB :
                result = USB_disk_initialize();
                // translate the reslut code here

                return stat;
        }
        return STA_NOINIT;
*/
    return 0;
}



/*-----------------------------------------------------------------------*/
/* Return Disk Status                                                    */

DSTATUS disk_status (
        BYTE drv                /* Physical drive nmuber (0..) */
)
{
/* MV
        DSTATUS stat;
        int result;

        switch (drv) {
        case ATA :
                result = ATA_disk_status();
                // translate the reslut code here

                return stat;

        case MMC :
                result = MMC_disk_status();
                // translate the reslut code here

                return stat;

        case USB :
                result = USB_disk_status();
                // translate the reslut code here

                return stat;
        }
        return STA_NOINIT;
*/
        return 0;
}



/*-----------------------------------------------------------------------*/
/* Read Sector(s)                                                        */

DRESULT disk_read (
        BYTE drv,               /* Physical drive nmuber (0..) */
        BYTE *buff,             /* Data buffer to store read data */
        DWORD sector,   /* Sector address (LBA) */
        BYTE count              /* Number of sectors to read (1..255) */
)
{
/* MV
        DRESULT res;
        int result;

        switch (drv) {
        case ATA :
                result = ATA_disk_read(buff, sector, count);
                // translate the reslut code here

                return res;

        case MMC :
                result = MMC_disk_read(buff, sector, count);
                // translate the reslut code here

                return res;

        case USB :
                result = USB_disk_read(buff, sector, count);
                // translate the reslut code here

                return res;
        }
        return RES_PARERR;
*/
   //TRACE_ALL("/%d",sector);
    int i;
    uint32_t res;
    for(i = 0; i < count; i++) {
        res = sd_readsector(sector, buff, 0, 0);

        sector++;
    // TODO velikost sectoru by mela byt dynamicka
        buff += 512;

        if (res == SD_ERROR)
            return RES_ERROR;
    }
    return RES_OK;
}



/*-----------------------------------------------------------------------*/
/* Write Sector(s)                                                       */

#if _READONLY == 0
DRESULT disk_write (
        BYTE drv,                       /* Physical drive nmuber (0..) */
        const BYTE *buff,       /* Data to be written */
        DWORD sector,           /* Sector address (LBA) */
        BYTE count                      /* Number of sectors to write (1..255) */
)
{
/* MV
        DRESULT res;
        int result;

        switch (drv) {
        case ATA :
                result = ATA_disk_write(buff, sector, count);
                // translate the reslut code here

                return res;

        case MMC :
                result = MMC_disk_write(buff, sector, count);
                // translate the reslut code here

                return res;

        case USB :
                result = USB_disk_write(buff, sector, count);
                // translate the reslut code here

                return res;
        }
        return RES_PARERR;
*/
    int i;
    uint32_t res;
    for(i = 0; i < count; i++) {
        res = sd_writesector(sector, buff, 0, 0);

        sector++;
        buff += 512;

        if (res == SD_ERROR)
            return RES_ERROR;
    }
    return RES_OK;
}
#endif /* _READONLY */



/*-----------------------------------------------------------------------*/
/* Miscellaneous Functions                                               */


DRESULT disk_ioctl (
        BYTE drv,               /* Physical drive nmuber (0..) */
        BYTE ctrl,              /* Control code */
        void *buff              /* Buffer to send/receive control data */
)
{
        DRESULT res;
/* MV
        int result;

        switch (drv) {
        case ATA :
                // pre-process here

                result = ATA_disk_ioctl(ctrl, buff);
                // post-process here

                return res;

        case MMC :
                // pre-process here

                result = MMC_disk_ioctl(ctrl, buff);
                // post-process here

                return res;

        case USB :
                // pre-process here

                result = USB_disk_ioctl(ctrl, buff);
                // post-process here

                return res;
        }
        return RES_PARERR;
*/
    res = RES_OK;
    return res;
}

DWORD get_fattime (void)
{
  return 0x01000005;
};


