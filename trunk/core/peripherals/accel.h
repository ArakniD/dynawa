#ifndef ACCEL_H_
#define ACCEL_H_

#include <stdint.h>

#define SPIACCEL_REG_XL (0x28)
#define SPIACCEL_REG_YL (0x2A)
#define SPIACCEL_REG_ZL (0x2C)

#define SPIACCEL_CTRL_REG1 0x20
#define SPIACCEL_CTRL_REG2 0x21
#define SPIACCEL_CTRL_REG3 0x22



//read:
#define SPIACCEL_REGREAD 0x80
#define SPIACCEL_REGWRITE 0
//multiple read:
#define SPIACCEL_REGMREAD 0x40
 
#endif // ACCEL_H_

