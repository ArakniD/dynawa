#include "dac7311.h"
#include "board/hardware_conf.h"
#include "types.h"
#include "debug/trace.h"

#define SAMPLE_LEN 60000

//uint16_t sample[SAMPLE_LEN];
uint16_t *sample;

#if DAC7311_LOOPBACK
uint16_t rcv_sample[SAMPLE_LEN];
#endif

void audioIsr_Wrapper( );

uint32_t audio_start;

void audio_play() {
    TRACE_INFO("audio_play() %d\r\n", Timer_tick_count());

    int i;
    uint16_t *p = (uint16_t *)0x10001b38;
    sample = p;

    bool high = true;
#if 0
    for(i = 0; i < SAMPLE_LEN; i++) {
        //sample[i] = p[i] & 0x3ffc;
        sample[i] = high ? 0x3ffc : 0; // loudest signal
        //sample[i] = high ? 0x4000 : 0; // shuldn't be heard
        //sample[i] = high ? 0x2000 : 0; // loudest bit
        //sample[i] = high ? 0x0004 : 0; // weakest bit
        //sample[i] = 0xaaaa;
        if (!(i % 2))
            high = !high; 
#if DAC7311_LOOPBACK
        rcv_sample[i] = 0x6969;
#endif
    }
#endif

    // Configure and enable the SSC interrupt
    AIC_ConfigureIT(BOARD_DAC7311_SSC_ID, 0, audioIsr_Wrapper);
    AIC_EnableIT(BOARD_DAC7311_SSC_ID);

    DAC7311_Enable(500, 2, MCK);

    audio_start = Timer_tick_count();
#if 1  // DMA Playback
    SSC_WriteBuffer(BOARD_DAC7311_SSC, (void *) sample, SAMPLE_LEN);
    SSC_WriteBuffer(BOARD_DAC7311_SSC, (void *) sample, SAMPLE_LEN); // 2nd DMA buffer
    SSC_EnableInterrupts(BOARD_DAC7311_SSC, AT91C_SSC_TXBUFE | AT91C_SSC_ENDTX);
#elif 0 // CPU Playback
    while (1) {
        for(i=0; i<SAMPLE_LEN; i++) {
            SSC_Write(BOARD_DAC7311_SSC, sample[i]);
        }
    }
#elif DAC7311_LOOPBACK && 0 // loopback test, DMA
    SSC_ReadBuffer(BOARD_DAC7311_SSC, (void *) rcv_sample, 10);
    SSC_EnableInterrupts(BOARD_DAC7311_SSC, AT91C_SSC_TXBUFE | AT91C_SSC_ENDTX | AT91C_SSC_RXBUFF | AT91C_SSC_ENDRX);
    for(i=0; i<10; i++) {
        //SSC_Write(BOARD_DAC7311_SSC, i + 1);
        SSC_Write(BOARD_DAC7311_SSC, 0xaaaa);
    }
#elif DAC7311_LOOPBACK && 0 // loopback test, DMA
    SSC_ReadBuffer(BOARD_DAC7311_SSC, (void *) rcv_sample, 10);
    SSC_WriteBuffer(BOARD_DAC7311_SSC, (void *) sample, 10);
    SSC_EnableInterrupts(BOARD_DAC7311_SSC, AT91C_SSC_TXBUFE | AT91C_SSC_ENDTX | AT91C_SSC_RXBUFF | AT91C_SSC_ENDRX);
#elif DAC7311_LOOPBACK && 0 // loopback test, CPU
    for(i=0; i<10; i++) {
        //SSC_Write(BOARD_DAC7311_SSC, i + 1);
        SSC_Write(BOARD_DAC7311_SSC, 0xaaaa);
        uint32_t w = SSC_Read(BOARD_DAC7311_SSC);
        TRACE_INFO("ssc %d %x\r\n", i, w);
    }
#endif
}
