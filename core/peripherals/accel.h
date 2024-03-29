#ifndef ACCEL_H_
#define ACCEL_H_

#include <stdint.h>

#define ACCEL_REG_WHO_AM_I 0x0F
#define ACCEL_REG_OFFSET_X 0x16
#define ACCEL_REG_OFFSET_Y 0x17
#define ACCEL_REG_OFFSET_Z 0x18
#define ACCEL_REG_GAIN_X 0x19
#define ACCEL_REG_GAIN_Y 0x1A
#define ACCEL_REG_GAIN_Z 0x1B
#define ACCEL_REG_CTRL_REG1 0x20
#define ACCEL_REG_CTRL_REG2 0x21
#define ACCEL_REG_CTRL_REG3 0x22
#define ACCEL_REG_HP_FILTER_RESET 0x23
#define ACCEL_REG_STATUS_REG 0x27
#define ACCEL_REG_OUTX_L 0x28
#define ACCEL_REG_OUTX_H 0x29
#define ACCEL_REG_OUTY_L 0x2A
#define ACCEL_REG_OUTY_H 0x2B
#define ACCEL_REG_OUTZ_L 0x2C
#define ACCEL_REG_OUTZ_H 0x2D
#define ACCEL_REG_FF_WU_CFG 0x30
#define ACCEL_REG_FF_WU_SRC 0x31
#define ACCEL_REG_FF_WU_ACK 0x32
#define ACCEL_REG_FF_WU_THS_L 0x34
#define ACCEL_REG_FF_WU_THS_H 0x35
#define ACCEL_REG_FF_WU_DURATION 0x36
#define ACCEL_REG_DD_CFG 0x38
#define ACCEL_REG_DD_SRC 0x39
#define ACCEL_REG_DD_ACK 0x3A
#define ACCEL_REG_DD_THSI_L 0x3C
#define ACCEL_REG_DD_THSI_H 0x3D
#define ACCEL_REG_DD_THSE_L 0x3E
#define ACCEL_REG_DD_THSE_H 0x3F

/*
#define ACCEL_CTRL_REG1 0x20
#define ACCEL_CTRL_REG2 0x21
#define ACCEL_CTRL_REG3 0x22

#define ACCEL_REG_XL (0x28)
#define CCEL_REG_YL (0x2A)
#define ACCEL_REG_ZL (0x2C)
*/

//read:
#define ACCEL_REG_READ 0x80
#define ACCEL_REG_WRITE 0
//multiple read:
#define ACCEL_REG_MULTI 0x40
 
#define ACCEL_REG_MASK  0x3f

#endif // ACCEL_H_

