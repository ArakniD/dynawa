#include "board/hardware_conf.h"
#include "dac7311.h"
#include "ssc.h"
#include "rtos.h"
#include "event.h"
#include "debug/trace.h"

extern uint32_t audio_start;

//------------------------------------------------------------------------------
/// Interrupt handler for the SSC. Loads the PDC with the audio data to stream.
//------------------------------------------------------------------------------
static void audio_isr(void)
{
    unsigned int status = BOARD_DAC7311_SSC->SSC_SR;
    unsigned int size;

    TRACE_INFO("audio_isr %d\r\n", Timer_tick_count_nonblock());

    // Last buffer sent
    if ((status & AT91C_SSC_TXBUFE) != 0) {

        //isWavPlaying = 0;
        SSC_DisableInterrupts(BOARD_DAC7311_SSC, AT91C_SSC_ENDTX | AT91C_SSC_TXBUFE);
        BOARD_DAC7311_SSC->SSC_PTCR = AT91C_PDC_TXTDIS;
        //DisplayMenu();

        event ev;
        ev.type = EVENT_AUDIO;
        ev.data.audio.data = Timer_tick_count_nonblock() - audio_start;
        event_post_isr(&ev);
    }
/*
    // One buffer sent & more buffers to send
    else if (remainingSamples > 0) {

        size = min(remainingSamples / (userWav->bitsPerSample / 8), 65535);
        SSC_WriteBuffer(BOARD_DAC7311_SSC, (void *) (WAV_FILE_ADDRESS + sizeof(WavHeader) + transmittedSamples), size);
        remainingSamples -= size * (userWav->bitsPerSample / 8);
        transmittedSamples += size * (userWav->bitsPerSample / 8);
    }
*/
    // One buffer sent, no more buffers
    else {
        SSC_DisableInterrupts(BOARD_DAC7311_SSC, AT91C_SSC_ENDTX);
    }
}

void audioIsr_Wrapper( void )
{
    /* Save the context of the interrupted task. */
    portSAVE_CONTEXT();

    /* Call the handler to do the work.  This must be a separate
       function to ensure the stack frame is set up correctly. */
    audio_isr();

    /* Restore the context of whichever task will execute next. */
    portRESTORE_CONTEXT();
}
