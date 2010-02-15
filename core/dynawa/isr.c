#include "debug/trace.h"

/// Default spurious interrupt handler. Infinite loop.
//------------------------------------------------------------------------------
void defaultSpuriousHandler( void )
{
    TRACE_ERROR("defaultSpuriousHandler\r\n");
    panic();
    //while (1);
}

//------------------------------------------------------------------------------
/// Default handler for fast interrupt requests. Infinite loop.
//------------------------------------------------------------------------------
void defaultFiqHandler( void )
{
    TRACE_ERROR("defaultFiqHandler\r\n");
    panic();
    //while (1);
}

//------------------------------------------------------------------------------
/// Default handler for standard interrupt requests. Infinite loop.
//------------------------------------------------------------------------------
void defaultIrqHandler( void )
{
    TRACE_ERROR("defaultIrqHandler\r\n");
    panic();
    //while (1);
}
