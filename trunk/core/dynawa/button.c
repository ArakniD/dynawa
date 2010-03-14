#include "button.h"
#include "io.h"
#include "debug/trace.h"
#include "event.h"
#include "task.h"
#include "queue.h"
#include "task_param.h"


#define BUTTON_TIMER_HW_INDEX   0
#define BUTTON_HOLD_TIMEOUT     1000

void button_isr(void* context);

#if defined(BUTTON_TASK)
xQueueHandle button_queue;
static xTaskHandle button_task_handle;
#endif

extern volatile portTickType xTickCount;

int button_pio[NUM_BUTTONS] = {
    32 + 18, 32 + 31, 32 + 21, 32 + 24, 32 + 27
};

Button button[NUM_BUTTONS];

void button_timer_handler(void* context) {
    uint8_t button_id = (uint8_t)context;
    TRACE_INFO("button_timer_handler butt %d\r\n", button_id);

    //if (button[button_id].down) {
    if (button[button_id].timer_started) {
        event ev;
        button[button_id].held = true;
        button[button_id].timer_started = false;

        TRACE_INFO("butt held %d\r\n", button_id);
        TRACE_INFO("ticks %d\r\n", xTickCount);

        ev.type = EVENT_BUTTON;
        ev.data.button.type = EVENT_BUTTON_HOLD;
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

#if defined(BUTTON_TASK)
static void button_task( void* p ) {
    TRACE_INFO("button task %x\r\n", xTaskGetCurrentTaskHandle());
    while (true) {
        int button_id;
        event ev;
        xQueueReceive(button_queue, &ev, -1);

        switch(ev.data.button.type) {
        case EVENT_BUTTON_DOWN:
            button_id = ev.data.button.id;
            Timer_start(&button[button_id].timer, BUTTON_HOLD_TIMEOUT, false, false);
            button[button_id].timer_started = true;
            button[button_id].held = false;

            break;
        case EVENT_BUTTON_UP:
            button_id = ev.data.button.id;
            if (!button[button_id].held) {
                button[button_id].timer_started = false;

                Timer_stop(&button[button_id].timer);
            }
            button[button_id].held = false;
            break;
        }
        event_post(&ev);
    }
}
#endif

int button_init () {
    int i;

#if defined(BUTTON_TASK)
    button_queue = xQueueCreate(10, sizeof(event));
#endif

    for(i = 0; i < NUM_BUTTONS; i++) {
        button[i].down = false;
        button[i].held = false;

        Io_init(&button[i].io, button_pio[i], IO_GPIO, INPUT);

        Timer_init(&button[i].timer, BUTTON_TIMER_HW_INDEX);
        Timer_setHandler(&button[i].timer, button_timer_handler, i);
        button[i].timer_started = false;

        Io_addInterruptHandler(&button[i].io, button_isr, i);
    }

#if defined(BUTTON_TASK)
    if (xTaskCreate( button_task, "button", TASK_STACK_SIZE(TASK_BUTTON_STACK), NULL, TASK_BUTTON_PRI, &button_task_handle ) != 1 ) {
        return -1;
    }
#endif

    return 0;
}

