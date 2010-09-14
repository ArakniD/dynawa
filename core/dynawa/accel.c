#include "io.h"
#include "accel.h"
#include "debug/trace.h"
#include "event.h"
#include "task.h"
#include "queue.h"
#include "task_param.h"

#define PIO_ACCEL  IO_PB20

static xTaskHandle accel_task_handle;
xQueueHandle accel_queue;

static Io accel_io;

static bool accel_wakeup_pin_high = false;

void accel_io_isr_handler(void* context) {
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

static void accel_task( void* p ) {
    TRACE_INFO("accel task %x\r\n", xTaskGetCurrentTaskHandle());
    
    accel_stop();

    Task_sleep(10);

    accel_start();

    Task_sleep(10);

    while (true) {

        uint8_t accel_ev;
        xQueueReceive(accel_queue, &accel_ev, -1);


        spi_lock();
        uint8_t src = accel_reg_read8(ACCEL_REG_DD_SRC);

        int16_t x = 0, y = 0, z = 0;
        accel_read(&x, &y, &z, false);

        accel_reg_read8(ACCEL_REG_DD_ACK);
        spi_unlock();

        TRACE_ACCEL("accel %x %d %d %d\r\n", src, x, y, z);

        event ev;
        ev.type = EVENT_ACCEL;
        ev.data.accel.gesture = 1;
        event_post(&ev);

    }
}

int accel_init () {
    accel_queue = xQueueCreate(1, sizeof(uint8_t));

    Io_init(&accel_io, PIO_ACCEL, IO_GPIO, INPUT);
    Io_addInterruptHandler(&accel_io, accel_io_isr_handler, NULL);

    if (xTaskCreate( accel_task, "accel", TASK_STACK_SIZE(TASK_ACCEL_STACK), NULL, TASK_ACCEL_PRI, &accel_task_handle ) != 1 ) {
        return -1;
    }

    return 0;
}

