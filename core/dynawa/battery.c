#include "battery.h"
#include "io.h"
#include "debug/trace.h"
#include "event.h"
#include "task.h"
#include "queue.h"
#include "task_param.h"

static xTaskHandle battery_task_handle;
static gasgauge_stats _stats;

int battery_get_stats (gasgauge_stats *stats) {
    memcpy (stats, &_stats, sizeof(_stats));
}

static void battery_task( void* p ) {
    TRACE_INFO("battery task %x\r\n", xTaskGetCurrentTaskHandle());
    while (true) {
        gasgauge_get_stats(&_stats);
    
        // TODO: BATTERY_STATE_CRITICAL

        if (_stats.state == GASGAUGE_STATE_NO_CHARGE) {
            if (_stats.voltage < 4050) {
                gasgauge_charge(true);

                event ev;
                ev.type = EVENT_BATTERY;
                ev.data.battery.state = BATTERY_STATE_CHARGING;
                event_post(&ev);
            }
        } else if (_stats.state == GASGAUGE_STATE_CHARGED) {
            gasgauge_charge(false);

            event ev;
            ev.type = EVENT_BATTERY;
            ev.data.battery.state = BATTERY_STATE_CHARGED;
            event_post(&ev);
        }
        Task_sleep(10000);
    }
}

int battery_init () {
    //Io_init(&button[i].io, button_pio[i], IO_GPIO, INPUT);

    if (xTaskCreate( battery_task, "battery", TASK_STACK_SIZE(TASK_BATTERY_STACK), NULL, TASK_BATTERY_PRI, &battery_task_handle ) != 1 ) {
        return -1;
    }

    return 0;
}

