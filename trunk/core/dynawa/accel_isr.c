#include "debug/trace.h"
#include "rtos.h"
#include "task.h"
#include "queue.h"

extern xQueueHandle accel_queue;

static bool accel_wakeup_pin_high = false;

void accel_isr(void* context) {
    accel_wakeup_pin_high = !accel_wakeup_pin_high;

    if (!accel_wakeup_pin_high) {
        return;
    }

    portBASE_TYPE xHigherPriorityTaskWoken;
    uint8_t ev = 1;
    xQueueSendFromISR(accel_queue, &ev, &xHigherPriorityTaskWoken);

    if(xHigherPriorityTaskWoken) {
        portYIELD_FROM_ISR();
    }
}
