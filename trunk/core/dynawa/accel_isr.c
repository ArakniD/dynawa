#include "debug/trace.h"
#include "rtos.h"
#include "task.h"
#include "queue.h"

extern xQueueHandle accel_queue;

void accel_isr(void* context) {
    portBASE_TYPE xHigherPriorityTaskWoken;
    uint8_t ev = 1;
    xQueueSendFromISR(accel_queue, &ev, &xHigherPriorityTaskWoken);

    if(xHigherPriorityTaskWoken) {
        portYIELD_FROM_ISR();
    }
}
