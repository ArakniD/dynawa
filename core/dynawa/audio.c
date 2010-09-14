#include "dac7311.h"
#include "board/hardware_conf.h"
#include "types.h"
#include "debug/trace.h"

#define SAMPLE_LEN 60000

static uint16_t sample[SAMPLE_LEN];

void audioIsr_Wrapper( );

uint32_t audio_start;

void audio_play() {
    TRACE_INFO("audio_play() %d\r\n", Timer_tick_count());

    int i;
    uint16_t *p = (uint16_t *)0x10001b38;

    bool high = true;
    for(i = 0; i < SAMPLE_LEN; i++) {
        //sample[i] = p[i] & 0x3ffc;
        sample[i] = high ? 0x3ffc : 0;
        if (!(i % 10))
            high = !high; 
    }

    // Configure and enable the SSC interrupt
    AIC_ConfigureIT(BOARD_DAC7311_SSC_ID, 0, audioIsr_Wrapper);
    AIC_EnableIT(BOARD_DAC7311_SSC_ID);

    DAC7311_Enable(10000, 16 / 8, MCK);

    audio_start = Timer_tick_count();
    SSC_WriteBuffer(BOARD_DAC7311_SSC, (void *) sample, SAMPLE_LEN);
    SSC_EnableInterrupts(BOARD_DAC7311_SSC, AT91C_SSC_TXBUFE | AT91C_SSC_ENDTX);
}
