#include "event.h"
#include "timer_event.h"
#include "debug/trace.h"

void lua_timer_handler(void *context) {
    event ev;
    ev.type = EVENT_TIMER;    
    ev.data.timer.type = EVENT_TIMER_FIRED;    
    ev.data.timer.handle = (TimerHandle)context;    

    TRACE_LUA("lua_timer_handler %x\r\n", context);
    event_post_isr(&ev);
}
