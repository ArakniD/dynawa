#include "button.h"
#include "io.h"
#include "debug/trace.h"
#include "event.h"
#include "task.h"
#include "queue.h"


#define BUTTON_TIMER_HW_INDEX   0
#define BUTTON_HOLD_TIMEOUT     1000

#if defined(BUTTON_TASK)
extern xQueueHandle button_queue;
#endif

extern volatile portTickType xTickCount;

extern Button button[NUM_BUTTONS];

void button_isr(void* context) {
    event ev;

    uint8_t button_id = (uint8_t)context;

    bool button_down = !Io_value(&button[button_id].io); 
    TRACE_INFO("butt %d %d (%d)\r\n", button_id, button_down, button[button_id].down);

    if (button_down) {
        if (!button[button_id].down) {
            button[button_id].down = true;

            TRACE_INFO("ticks %d\r\n", xTickCount);
#if !defined(BUTTON_TASK)
            //Timer_stop(&button[button_id].timer);
            Timer_start(&button[button_id].timer, BUTTON_HOLD_TIMEOUT, false, false);
            button[button_id].timer_started = true;

            button[button_id].held = false;
#endif


            ev.type = EVENT_BUTTON_DOWN;
            ev.data.button.id = button_id;
#if defined(BUTTON_TASK)
            portBASE_TYPE xHigherPriorityTaskWoken;
            xQueueSendFromISR(button_queue, &ev, &xHigherPriorityTaskWoken);

            if(xHigherPriorityTaskWoken) {
                portYIELD_FROM_ISR();
            }
#else
            event_post_isr(&ev);
#endif
        }
    } else {
        if(button[button_id].down) {
            button[button_id].down = false;


#if !defined(BUTTON_TASK)
            if (!button[button_id].held) {
// MV TODO: !!! nested interrupts !!! is it ok???
                button[button_id].timer_started = false;

                Timer_stop(&button[button_id].timer);
            }
            button[button_id].held = false;
#endif

            ev.type = EVENT_BUTTON_UP;
            ev.data.button.id = button_id;
#if defined(BUTTON_TASK)
            portBASE_TYPE xHigherPriorityTaskWoken;
            xQueueSendFromISR(button_queue, &ev, &xHigherPriorityTaskWoken);

            if(xHigherPriorityTaskWoken) {
                portYIELD_FROM_ISR();
            }
#else
            event_post_isr(&ev);
#endif
        }
    }
}
