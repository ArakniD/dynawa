#include "stdio.h"
#include "dac7311.h"
#include "board/hardware_conf.h"
#include "types.h"
#include "audio.h"
#include "utils/wav.h"
#include "debug/trace.h"

#define SAMPLE_LEN 60000

static WavHeader wav_header;

audio_sample *audio_current_sample = NULL;
uint32_t audio_current_sample_start;
uint32_t audio_current_sample_remaining;
uint32_t audio_current_sample_transmitted;
uint32_t audio_current_sample_loop;
void* (*audio_current_sample_stop_callback)(void *arg);
void* audio_current_sample_stop_callback_arg;

void audioIsr_Wrapper( );


void audio_play(audio_sample *sample, uint32_t sample_rate, uint32_t loop, void* (f_stop_callback)(void *arg), void* stop_callback_arg) {
    TRACE_INFO("audio_play() %d\r\n", Timer_tick_count());

    audio_stop();
    // Configure and enable the SSC interrupt
    AIC_ConfigureIT(BOARD_DAC7311_SSC_ID, 0, audioIsr_Wrapper);
    AIC_EnableIT(BOARD_DAC7311_SSC_ID);

    //DAC7311_Enable(48000, 2, MCK);
    DAC7311_Enable(sample_rate ? sample_rate : sample->sample_rate, 2, MCK);

    audio_current_sample = sample;
    audio_current_sample_loop = loop ? loop : sample->loop;
    audio_current_sample_stop_callback = f_stop_callback;
    audio_current_sample_stop_callback_arg = stop_callback_arg;
    audio_current_sample_start = Timer_tick_count();

    audio_current_sample_remaining = sample->length;
    audio_current_sample_transmitted = 0;

    uint32_t size = min(audio_current_sample_remaining, 0xffff);

    SSC_WriteBuffer(BOARD_DAC7311_SSC, (void *) AUDIO_SAMPLE_DATA(sample), size);
    audio_current_sample_remaining -= size;
    audio_current_sample_transmitted += size;

    if (audio_current_sample_remaining == 0 && loop) {
        audio_current_sample_remaining = sample->length;
        audio_current_sample_transmitted = 0;
    }
    if (audio_current_sample_remaining > 0) {
        uint32_t size = min(audio_current_sample_remaining, 0xffff);
        
        SSC_WriteBuffer(BOARD_DAC7311_SSC, (void *) &AUDIO_SAMPLE_DATA(sample)[audio_current_sample_transmitted], size); // 2nd DMA buffer
        audio_current_sample_remaining -= size;
        audio_current_sample_transmitted += size;
    }
    SSC_EnableInterrupts(BOARD_DAC7311_SSC, AT91C_SSC_TXBUFE | AT91C_SSC_ENDTX);
}

void audio_stop(void)
{
    if (audio_current_sample == NULL) {
        return;
    }
    SSC_DisableInterrupts(BOARD_DAC7311_SSC, AT91C_SSC_TXBUFE | AT91C_SSC_ENDTX);
    BOARD_DAC7311_SSC->SSC_PTCR = AT91C_PDC_TXTDIS;
    BOARD_DAC7311_SSC->SSC_TNCR = 0;
    BOARD_DAC7311_SSC->SSC_TCR = 0;

    DAC7311_Disable();

    if (audio_current_sample_stop_callback != NULL) {
        (*audio_current_sample_stop_callback)(audio_current_sample_stop_callback_arg);
    }
    audio_current_sample = NULL;
}  

#define WAV_BUF_SIZE 512
static uint8_t wav_buf[WAV_BUF_SIZE];

audio_sample* audio_sample_from_wav_file(const char *filename, int8_t volume, uint16_t sample_rate, int32_t loop, void* (f_malloc)(size_t size, void *arg), void *arg) {

    TRACE_AUDIO("audio_sample_from_wav_file(%s)\r\n", filename);
    audio_sample *sample;

    FILE *f = fopen(filename, "r");

    if (f == NULL) {
        TRACE_AUDIO("file not found\r\n");
        return NULL;
    }
    size_t n = fread(&wav_header, sizeof(wav_header), 1, f);
    if (n != 1) {
        TRACE_AUDIO("not a wav (1)\r\n");
        fclose(f);
        return NULL;
    }
    if (!WAV_IsValid((WavHeader*)&wav_header)) {
        TRACE_AUDIO("not a wav (2)\r\n");
        fclose(f);
        return NULL;
    }

    if (wav_header.audioFormat != 1) {
        TRACE_AUDIO("not uncompressed\r\n");
        fclose(f);
        return NULL;
    }
    if (!(wav_header.bitsPerSample == 8 || wav_header.bitsPerSample == 16)) {
        TRACE_AUDIO("unsupported sample size\r\n");
        fclose(f);
        return NULL;
    }
    uint8_t wav_sample_size = wav_header.bitsPerSample / 8;
    uint8_t wav_num_channels = wav_header.numChannels;
    int wav_num_samples = wav_header.subchunk2Size / wav_sample_size;
    int wav_num_units = wav_num_samples / wav_num_channels;
    int num_samples = wav_num_samples / wav_num_channels;
    int sample_len = num_samples * 2;

#if 1
    TRACE_AUDIO("info sample rate %d\r\n", wav_header.sampleRate);
    TRACE_AUDIO("info byte rate %d\r\n", wav_header.byteRate);
    TRACE_AUDIO("info wav_sample_size %d\r\n", wav_sample_size);
    TRACE_AUDIO("info wav_num_channels %d\r\n", wav_num_channels);
    TRACE_AUDIO("info wav_num_samples %d\r\n", wav_num_samples);
    TRACE_AUDIO("info num_samples %d\r\n", num_samples);
    TRACE_AUDIO("info sample_len %d\r\n", sample_len);
#endif


    sample = (audio_sample*)(*f_malloc)(sizeof(audio_sample) + sample_len, arg); 
    if (sample == NULL) {
        TRACE_AUDIO("not enough mem\n");
        fclose(f);
        return NULL;
    }

    uint16_t *p = AUDIO_SAMPLE_DATA(sample);
    memset(p, 0, sample_len);

    sample->length = num_samples;
    sample->sample_rate = sample_rate ? sample_rate : wav_header.sampleRate;
    sample->loop = loop;

    int avail = 0;
    int pos;
    uint16_t min = 0xffff, max = 0;
    while(wav_num_units--) {
        int i;
        uint16_t s = 0;
        for(i = 0; i < wav_num_channels; i++) {
            if (!avail) {
                avail = fread(wav_buf, 1, WAV_BUF_SIZE, f);
                if (!avail) {
                    TRACE_AUDIO("file too short\n");
                    free(sample);
                    fclose(f);
                    return NULL;
                }
                pos = 0;
            }
            switch(wav_sample_size) {
            case 1:
                // 8-bit unsigned (0 to 255)
                //s += (wav_buf[pos] / wav_num_channels) << 6;
                s += (wav_buf[pos] / wav_num_channels) << 8;
                break;
            case 2:
                // 16-bit signed (-32768 to 32767)
                //if (!i) // left channel only
                //if (i) // right channel only
                {
                    int16_t ss = ((int16_t*)wav_buf)[pos];
                    uint16_t us = ss + 32768;
                    
                    //s += (us / wav_num_channels) >> 2;
                    s += (us / wav_num_channels);
                    //TRACE_AUDIO("%d %x %x\r\n", i, us, s);
                }
                break; 
            default:
                panic("sample size");
            }
            pos++;
            avail -= wav_sample_size;

            if (avail < 0) 
                panic("sample avail");
        }
        //TRACE_AUDIO("[%x]=%x\r\n", p, s);
        //*p++ = s;
        if (s > max) {
            max = s;
        }
        if (s < min) {
            min = s;
        }
        *p++ = s >> 2;
    }
#if 0
    p = (uint16_t*)((void*)sample + sizeof(audio_sample));
    {
        int i;
        for(i = 0; i < num_samples; i++) {
            TRACE_AUDIO("%04x ", p[i]);
            if (! (i % 16)) {
                TRACE_AUDIO("\r\n");
            }
        }
        TRACE_AUDIO("\r\n");
    }
#endif

    TRACE_AUDIO("sample %x %x\r\n", (void*)sample + sizeof(audio_sample) + sample_len, p);
    TRACE_AUDIO("sample min %d max %d\r\n", min, max);
    fclose(f);

    TRACE_AUDIO("ok\n");
    return sample;
}
