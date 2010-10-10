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

int usb_init(void) {
}

int usb_close(void) {
}
