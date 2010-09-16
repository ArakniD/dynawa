#ifndef DAC7311_H
#define DAC7311_H

//------------------------------------------------------------------------------
//         Exported functions
//------------------------------------------------------------------------------

#define DAC7311_LOOPBACK    0

extern void DAC7311_Enable(unsigned int Fs,
                            unsigned int sampleSize,
                            unsigned int masterClock);
extern void DAC7311_Disable();
extern void DAC7311_SetMuteStatus(unsigned char muted);

#endif //#ifndef DAC7311_H
