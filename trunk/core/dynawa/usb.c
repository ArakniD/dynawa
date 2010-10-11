#include "io.h"
#include "usb.h"
#include "debug/trace.h"
#include "event.h"
#include "task.h"
#include "queue.h"
#include "task_param.h"
//#include "../usb/common/core/.h"
#include "USBGenericRequest.h"

#define PIO_USB_DETECT IO_PB22

extern xQueueHandle battery_queue;

bool usb_connected = false;

static xTaskHandle usb_task_handle;
xQueueHandle usb_queue;
static Io usb_io;
int usb_mode = 2;

//------------------------------------------------------------------------------
/// Re-implemented callback, invoked when a new USB Request is received.
//------------------------------------------------------------------------------
void USBDCallbacks_RequestReceived(const USBGenericRequest *request)
{
    switch(usb_mode) {
    case 1:
//-----------------------------------------------------------------------------
//         Callback re-implementation
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
/// Invoked when a new SETUP request is received from the host. Forwards the
/// request to the Mass Storage device driver handler function.
/// \param request  Pointer to a USBGenericRequest instance.
//-----------------------------------------------------------------------------
        USBDCallbacks_RequestReceived_MSD(request);
    case 2:
        USBDCallbacks_RequestReceived_CDC(request);
    }
}

//-----------------------------------------------------------------------------
/// Invoked when the configuration of the device changes. Resets the mass
/// storage driver.
/// \param cfgnum New configuration number.
//-----------------------------------------------------------------------------
void USBDDriverCallbacks_ConfigurationChanged(unsigned char cfgnum)
{
    switch(usb_mode) {
    case 1:
        USBDDriverCallbacks_ConfigurationChanged_MSD(cfgnum);
    }
}

#if defined(USB_COMPOSITE)
#include <usb/device/massstorage/MSDDriver.h>
#include <usb/device/massstorage/MSDLun.h>
#include <memories/Media.h>
#include <memories/MEDSD.h>
#endif

void usb( void* parameters );
void usb_msd( void* parameters );

#if defined(USB_COMPOSITE)
/// Use for power management
#define STATE_IDLE    0
/// The USB device is in suspend state
#define STATE_SUSPEND 4
/// The USB device is in resume state
#define STATE_RESUME  5

/// Size of one block in bytes.
#define BLOCK_SIZE          512

//-----------------------------------------------------------------------------
//      Internal variables
//-----------------------------------------------------------------------------
// State of USB, for suspend and resume
unsigned char USBState = STATE_IDLE;

//------------------------------------------------------------------------------
//         Callbacks re-implementation
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Invoked when the USB device leaves the Suspended state. By default,
// configures the LEDs.
//------------------------------------------------------------------------------
void USBDCallbacks_Resumed(void)
{
    // Initialize LEDs
    //LED_Configure(USBD_LEDPOWER);
    //LED_Set(USBD_LEDPOWER);
    //LED_Configure(USBD_LEDUSB);
    //LED_Clear(USBD_LEDUSB);
    USBState = STATE_RESUME;
}

//------------------------------------------------------------------------------
// Invoked when the USB device gets suspended. By default, turns off all LEDs.
//------------------------------------------------------------------------------
void USBDCallbacks_Suspended(void)
{
    // Turn off LEDs
    //LED_Clear(USBD_LEDPOWER);
    //LED_Clear(USBD_LEDUSB);
    USBState = STATE_SUSPEND;
}

//-----------------------------------------------------------------------------
/// Initialize MSD Media & LUNs
//-----------------------------------------------------------------------------

/// Maximum number of LUNs which can be defined.
#define MAX_LUNS            2

//- MSD
/// Available medias.
Media medias[MAX_LUNS];

/// Device LUNs.
MSDLun luns[MAX_LUNS];

/// LUN read/write buffer.
unsigned char msdBuffer[BLOCK_SIZE];

void MSDDInitialize()
{
    // Memory initialization
    TRACE_INFO("LUN SD\n\r");

    uint32_t sd_size = sd_info();
    SD_Initialize(&(medias[numMedias]), sd_size);
    LUN_Init(&(luns[numMedias]), &(medias[numMedias]),
            msdBuffer, 0, sd_size, BLOCK_SIZE);
    numMedias++;

    //ASSERT(numMedias > 0, "Error: No media defined.\n\r");
    TRACE_INFO("%u medias defined\n\r", numMedias);

    // BOT driver initialization
    MSDDFunctionDriver_Initialize(luns, numMedias);
    //MSDDriver_Initialize(luns, numMedias);
}

void usb( void* p )
{
    (void)p;

    TRACE_INFO("usb\r\n");

    /*
       spi_init();
       Task_sleep(200);
       if ( sd_init() != SD_OK ) {
       TRACE_ERROR("SD card init failed!\r\n");
       }
       */
    UsbSerial_open();
    MSDDInitialize();
    COMPOSITEDDriver_Initialize();

    unsigned int count = 0;
    bool childrenStarted = false;
    while(1) {
        if ( USBD_GetState() < USBD_STATE_CONFIGURED ) {
            TRACE_INFO("path 1\r\n");
            USBD_Connect();

            while( USBD_GetState() < USBD_STATE_CONFIGURED ) { // while usb is not active
                Task_sleep(10);        // wait around for a little bit
            }
            TRACE_INFO("connected\r\n");
            if (! childrenStarted) {
                childrenStarted = true;
                //Task_create( usb_msd, "USB_MSD", 1024, 1, NULL );
                monitorTaskStart();
            }
            /*
               while(1) {
               Task_sleep(10000);
               }
               */
        } else {
            //TRACE_INFO("path 2\r\n");
            MSDDriver_StateMachine();
        }
        if( USBState == STATE_SUSPEND ) {
            TRACE_INFO("suspend  !\n\r");
            //LowPowerMode();
            USBState = STATE_IDLE;
        }
        if( USBState == STATE_RESUME ) {
            // Return in normal MODE
            TRACE_INFO("resume !\n\r");
            //NormalPowerMode();
            USBState = STATE_IDLE;
        }
        //TRACE_INFO("loop %d\r\n", count);
        count++;
    }

    led_loop();
}

void usb_msd( void* p )
{
    (void)p;

    TRACE_INFO("usb_msd\r\n");

    while(1) {
        MSDDriver_StateMachine();
    }
}
#endif

static bool usb_pin_high = false;

void usb_io_isr_handler(void* context) {
    //usb_pin_high = !usb_pin_high;
    usb_pin_high = Io_value(&usb_io);

    uint8_t ev;
    if (usb_pin_high) {
        ev = WAKEUP_EVENT_USB_DISCONNECTED;
    } else {
        ev = WAKEUP_EVENT_USB_CONNECTED;
    }
    TRACE_INFO("usb_io_isr_handler usb %d\r\n", usb_pin_high);

    portBASE_TYPE xHigherPriorityTaskWoken;
    xQueueSendFromISR(usb_queue, &ev, &xHigherPriorityTaskWoken);

    if(xHigherPriorityTaskWoken) {
        portYIELD_FROM_ISR();
    }
}

static void usb_task( void* p ) {
    TRACE_INFO("usb task %x\r\n", xTaskGetCurrentTaskHandle());

    while (true) {
        uint8_t usb_event;

        xQueueReceive(usb_queue, &usb_event, -1);

        if (usb_event == WAKEUP_EVENT_USB_CONNECTED) {
            usb_connected = true;
            pm_lock();
            UsbSerial_open();

            // notify battery manager
            xQueueSend(battery_queue, &usb_event, 0);

            event ev;
            ev.type = EVENT_USB;
            ev.data.usb.state = EVENT_USB_CONNECTED;
            event_post(&ev);
        } else if (usb_event == WAKEUP_EVENT_USB_DISCONNECTED) {
            usb_connected = false;
            UsbSerial_close();
            pm_unlock();

            // notify battery manager
            xQueueSend(battery_queue, &usb_event, 0);

            event ev;
            ev.type = EVENT_USB;
            ev.data.usb.state = EVENT_USB_DISCONNECTED;
            event_post(&ev);
        }
    }
    vQueueDelete(usb_queue);
    vTaskDelete(NULL);
}

int usb_init(void) {
    usb_queue = xQueueCreate(1, sizeof(uint8_t));
    if (usb_queue == NULL) {
        panic("usb_init");
        return -1;
    }
 
    Io_init(&usb_io, PIO_USB_DETECT, IO_GPIO, INPUT);
    usb_pin_high = Io_value(&usb_io);

    if (!usb_pin_high) {
        usb_connected = true;
        pm_lock();
        UsbSerial_open();
    }

    TRACE_INFO("usb_init() usb %d\r\n", usb_pin_high);

    Io_addInterruptHandler(&usb_io, usb_io_isr_handler, NULL);    

    if (xTaskCreate( usb_task, "usb", TASK_STACK_SIZE(TASK_USB_STACK), NULL, TASK_USB_PRI, &usb_task_handle ) != 1 ) {
        return -1;
    }

    return 0;
}

int usb_close(void) {
    vQueueDelete(usb_queue);
    return 0;
}
