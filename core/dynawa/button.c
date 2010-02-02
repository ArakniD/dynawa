#include "button.h"
#include "io.h"
#include "debug/trace.h"
#include "event.h"


#define BUTTON_TIMER_HW_INDEX   0
#define BUTTON_HOLD_TIMEOUT     1000

int button_pio[NUM_BUTTONS] = {
    32 + 18, 32 + 31, 32 + 21, 32 + 24, 32 + 27
};

static Button button[NUM_BUTTONS];

void button_isr(void* context) {
    event ev;

    uint8_t button_id = (uint8_t)context;

    bool button_down = !Io_value(&button[button_id].io); 
    TRACE_INFO("butt %d %d (%d)\r\n", button_id, button_down, button[button_id].down);

    if (button_down) {
        if (!button[button_id].down) {
            button[button_id].down = true;
            button[button_id].held = false;

            //Timer_stop(&button[button_id].timer);
            Timer_start(&button[button_id].timer, BUTTON_HOLD_TIMEOUT, false, false);
            button[button_id].timer_started = true;

            ev.type = EVENT_BUTTON_DOWN;
            ev.data.button.id = button_id;
            event_post_isr(&ev);
        }
    } else {
        if(button[button_id].down) {
            button[button_id].down = false;
            button[button_id].held = false;

            if (!button[button_id].held) {
// MV TODO: !!! nested interrupts !!! is it ok???
                button[button_id].timer_started = false;

                Timer_stop(&button[button_id].timer);
            }
            ev.type = EVENT_BUTTON_UP;
            ev.data.button.id = button_id;
            event_post_isr(&ev);
        }
    }
}

void button_timer_handler(void* context) {
    uint8_t button_id = (uint8_t)context;
    TRACE_INFO("button_timer_handler butt %d\r\n", button_id);

    //if (button[button_id].down) {
    if (button[button_id].timer_started) {
        event ev;
        button[button_id].held = true;
        button[button_id].timer_started = false;

        TRACE_INFO("butt held %d\r\n", button_id);

        ev.type = EVENT_BUTTON_HOLD;
        ev.data.button.id = button_id;
        event_post_isr(&ev);
    }
}

int button_init () {
    int i;

    for(i = 0; i < NUM_BUTTONS; i++) {
        button[i].down = false;
        button[i].held = false;

        Io_init(&button[i].io, button_pio[i], IO_GPIO, INPUT);

        Timer_init(&button[i].timer, BUTTON_TIMER_HW_INDEX);
        Timer_setHandler(&button[i].timer, button_timer_handler, i);
        button[i].timer_started = false;

        Io_addInterruptHandler(&button[i].io, button_isr, i);
    }
}
