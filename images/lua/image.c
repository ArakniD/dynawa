#include "core.h"
#include "timer.h"
#include "led.h"
//#include "appled.h"
#include <debug/trace.h>
//#include "serial.h"
#include <rtos.h>
#include <usbserial.h>
#include <serial.h>
#include <audio.h>
#include <ff.h>
//#include <analogin.h>
#include <task_param.h>

#include "lua.h"

#include "sdcard/sdcard.h"

#if defined(USB_COMPOSITE)
#include <usb/device/massstorage/MSDDriver.h>
#include <usb/device/massstorage/MSDLun.h>
#include <memories/Media.h>
#include <memories/MEDSD.h>
#endif

#define PIN_LED  AT91C_PIO_PA0
#define LED_ON (*AT91C_PIOA_SODR = PIN_LED)
#define LED_OFF (*AT91C_PIOA_CODR = PIN_LED)
#define LED_TOGGLE (*AT91C_PIOA_PDSR & (1 << PIN_LED) ? LED_OFF : LED_ON)

static void *audio_malloc(size_t size, void *arg) {
    return malloc(size);
}

void blinkLoop( void* parameters );
void console( void* parameters );
void bc( void* parameters );
void lua( void* parameters );
void lua_event_loop( void* parameters );
void usb( void* parameters );
void usb_msd( void* parameters );
void bcsp( void* parameters );

Timer sys_timer;
bool in_panic_handler = false;

void panic(const char* msg) {
    if (!in_panic_handler) {
        in_panic_handler = true;
        AT91C_BASE_AIC->AIC_IDCR = 0xffffffff;
/*
        ledrgb_open();
        ledrgb_set(0x7, 0xe0, 0, 0);
*/
        oled_screen_state(true);

        scrWriteRect(0, 0, 159, 127, SCR_COLOR_RED);

        fontSetColor(SCR_COLOR_WHITE, SCR_COLOR_RED);
        fontSetCharPos(10, 10);
        fontSetCarridgeReturnPosX(10);

        xTaskHandle current_task= xTaskGetCurrentTaskHandle();
        TRACE_SCR("PANIC\r\n");
        TRACE_ERROR("!!!PANIC!!!\r\n");
        if (msg) {
            TRACE_SCR("\r\n%s", msg);
            TRACE_ERROR("%s\r\n", msg);
        }
        if (current_task) {
            TRACE_SCR("\r\nthandle: %x\r\ntname: %s", current_task, xTaskGetName(current_task));
            TRACE_ERROR("thandle: %x\r\ntname: %s\r\n", current_task, xTaskGetName(current_task));
        }
    }

    uint32_t count;
    while(1) {
        if (!(count % 10000))
            TRACE_ERROR("*");
        count++;
    }
    TRACE_ERROR("!!!PANIC2!!!\r\n");
}

void panic_abort(unsigned int abort_type, unsigned int abort_mem) {
    if (!in_panic_handler) {
        in_panic_handler = true;
        AT91C_BASE_AIC->AIC_IDCR = 0xffffffff;
/*
        ledrgb_open();
        ledrgb_set(0x7, 0xe0, 0, 0);
*/
        oled_screen_state(true);

        scrWriteRect(0, 0, 159, 127, SCR_COLOR_RED);
        
        fontSetColor(SCR_COLOR_WHITE, SCR_COLOR_RED);
        fontSetCharPos(10, 10);
        fontSetCarridgeReturnPosX(10);

        xTaskHandle current_task= xTaskGetCurrentTaskHandle();
        TRACE_ERROR("!!!ABORT!!! %x %x %x\r\n", abort_type, abort_mem, current_task);
        TRACE_SCR("ABORT\r\n\r\ntype: %d\r\naddr: %x", abort_type, abort_mem);
        if (current_task) {
            TRACE_SCR("\r\nthandle: %x\r\ntname: %s", current_task, xTaskGetName(current_task));
        }
    }

    uint32_t count;
    while(1) {
        if (!(count % 10000))
            TRACE_ERROR("*");
        count++;
    }
    TRACE_ERROR("!!!PANIC2!!!\r\n");
}

void test() {
    unsigned long ticks = xTaskGetTickCount();
    int i;
    for(i = 0; i < 100; i++) {
        scrWriteBitmapRGBA(0, 0, 159, 127, (uint8_t*)0);
    }
    ticks = xTaskGetTickCount() - ticks;

    TRACE_INFO("test1 %d\r\n", ticks);

    ticks = xTaskGetTickCount();
    for(i = 0; i < 100; i++) {
        scrWriteBitmapRGBA(0, 0, 159, 127, (uint8_t*)0x10080000);
    }
    ticks = xTaskGetTickCount() - ticks;

    TRACE_INFO("test2 %d\r\n", ticks);
}

void Run( ) // this task gets called as soon as we boot up.
{
    TRACE_INFO("Run\n\r");

//#ifndef CFG_SCHEDULER_RTT
#if 0
    Timer_init(&sys_timer, 0);
    Timer_setHandler(&sys_timer, NULL, NULL);
    Timer_start(&sys_timer, 24 * 3600, true, false);
    TRACE_INFO("sys timer ok\n\r");
#endif

#if 0
    scrInit();
    //oledInitHw();
    TRACE_INFO("scrInit ok\n\r");
#endif

#if 1
    spi_init();
    TRACE_INFO("spi_init ok\n\r");
    if ( sd_init() != SD_OK ) {
        TRACE_ERROR("SD card init failed!\r\n");
    }
    TRACE_INFO("sd_init ok\n\r");
#endif

#if 1
    i2c_init();
    TRACE_INFO("i2c_init ok\n\r");
#endif
#if 1
    rtc_init();
    TRACE_INFO("rtc_init ok\n\r");
#endif
#if 1
    gasgauge_init();
    TRACE_INFO("gasgauge_init ok\n\r");
#endif

    event_init(100);
    TRACE_INFO("event_init ok\n\r");

    //System* sys = System::get();
    //int free_mem = sys->freeMemory();
#if 1
    ledrgb_open();
    ledrgb_set(0x7, 0, 0, 0);
    ledrgb_close();
    TRACE_INFO("ledrgb ok\n\r");
#endif

    display_init();
    TRACE_INFO("display_init ok\n\r");
    display_power(1);
    TRACE_INFO("display_power ok\n\r");

#if 0
    //test();
    scrWriteRect(0,126,40,127,0xffffff);
    scrWriteRect(80,126,120,127,0xffffff);
#endif

#if 1
    battery_init();
    TRACE_INFO("battery_init ok\n\r");
#endif
#if 1
    accel_init();
    TRACE_INFO("accel_init ok\n\r");
#endif

    button_init();
    TRACE_INFO("button_init ok\n\r");
    bt_init();
    TRACE_INFO("bt_init ok\n\r");
    //bt_open();

#if 0
    rtc_open();
    rtc_set_epoch_seconds(1265399017); // 10/02/05 19:43
    TRACE_INFO("time: %d\r\n", rtc_get_epoch_seconds(NULL));
    rtc_close();
#endif
    
#if 0
    UsbSerial_open();
#endif
/*
    while( !UsbSerial_isActive() )
        Task_sleep(10);
       //Task_sleep(500);
*/

    //AnalogIn_test();
#if 0
    AnalogIn adc;
    AnalogIn_init(&adc, 7);
    //AnalogIn_value(&adc);
    AnalogIn_valueWait(&adc);
    AnalogIn_close(&adc);
#endif

    //Task_create( blinkLoop, "Blink", 400, 1, NULL );
    //Task_create( console, "console", 400, 1, NULL );
    //Task_create( bc, "BlueCore", 400, 1, NULL );
#if defined(USB_COMPOSITE)
    //Task_create( usb, "USB", 1024, 1, NULL );
#else
    //Task_create( lua, "LUA", 8192, 1, NULL );
#endif
    //Task_create( lua_event_loop, "lua", TASK_LUA_STACK, TASK_LUA_PRI, NULL );

#if 0
    {
        FATFS fatfs;
        FRESULT f;
        int err = 0;

        if ((f = disk_initialize (0)) != FR_OK) {
            f_printerror (f);
            return 1;
        }
        if ((f = f_mount (0, &fatfs)) != FR_OK) {
            f_printerror (f);
            return 1;
        }
        audio_sample *sample = audio_sample_from_wav_file("/sample.wav", -1, 0, 0, audio_malloc, NULL);
        
        if ((f = f_mount (0, NULL)) != FR_OK) {
            f_printerror (f);
        }

        if (sample == NULL)
            panic("sample");

        audio_play(sample, 0, 1, NULL, NULL);
        while(1)
            Task_sleep(10000);
    }
#endif
    //while(1) Task_sleep(10000);
    xTaskCreate(lua_event_loop, (signed char*)"lua", TASK_STACK_SIZE(TASK_LUA_STACK), NULL, TASK_LUA_PRI, NULL);

#if 0
    int i;
    for(i = 0; i < 100; i++) {
        TRACE_INFO("test %d\r\n", i);
        AnalogIn_test();
        Task_sleep(100);
    }
#endif

    //monitorTaskStart();

    //bt_open();
    //Task_create( bcsp, "BCSP", 8192, 1, NULL );

    //Serial usart(0);

    //UsbSerial* usb = UsbSerial::get();
    //MV Network* net = Network::get();

    // Fire up the OSC system and register the subsystems you want to use
    //  Osc_SetActive( true, true, true, true );
    //  // make sure OSC_SUBSYSTEM_COUNT (osc.h) is large enough to accomodate them all
    //  //Osc_RegisterSubsystem( AppLedOsc_GetName(), AppLedOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( DipSwitchOsc_GetName(), DipSwitchOsc_ReceiveMessage, DipSwitchOsc_Async );
    //  Osc_RegisterSubsystem( ServoOsc_GetName(), ServoOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( AnalogInOsc_GetName(), AnalogInOsc_ReceiveMessage, AnalogInOsc_Async );
    //  Osc_RegisterSubsystem( DigitalOutOsc_GetName(), DigitalOutOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( DigitalInOsc_GetName(), DigitalInOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( MotorOsc_GetName(), MotorOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( PwmOutOsc_GetName(), PwmOutOsc_ReceiveMessage, NULL );
    //  //Osc_RegisterSubsystem( LedOsc_GetName(), LedOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( DebugOsc_GetName(), DebugOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( SystemOsc_GetName(), SystemOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( NetworkOsc_GetName(), NetworkOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( SerialOsc_GetName(), SerialOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( IoOsc_GetName(), IoOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( StepperOsc_GetName(), StepperOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( XBeeOsc_GetName(), XBeeOsc_ReceiveMessage, XBeeOsc_Async );
    //  Osc_RegisterSubsystem( XBeeConfigOsc_GetName(), XBeeConfigOsc_ReceiveMessage, NULL );
    //  Osc_RegisterSubsystem( WebServerOsc_GetName(), WebServerOsc_ReceiveMessage, NULL );

    // Starts the network up.  Will not return until a network is found...
    // Network_SetActive( true );
}

// A very simple task...a good starting point for programming experiments.
// If you do anything more exciting than blink the LED in this task, however,
// you may need to increase the stack allocated to it above.

void led_loop ()
{
    Io led;
    Led_init(&led);

    while ( true )
    {
        Led_stateToggle(&led);
        Task_sleep( 1000 ); 
    }
}

void blinkLoop( void* p )
{
    (void)p;
    led_loop();
}


void console( void* p )
{
    (void)p;
    //Led led;
    Io led;
    Led_init(&led);
    //led.setState( 0 );

    UsbSerial_open();
    while( !UsbSerial_isActive() ) // while usb is not active
        Task_sleep(10);        // wait around for a little bit

    char b[10];
    int n;
    while(1) {
        n = UsbSerial_read(b, 10, -1);
        //led.stateToggle();
        //LED_TOGGLE;
        Led_stateToggle(&led);
        if (n)
            UsbSerial_write(b, n, -1);
    }
}

void bc( void* p )
{
    (void)p;
    //Led led;
    Io led;
    Led_init(&led);
    //led.setState( 0 );

    TRACE_INFO("bc1\r\n");
    Serial_open(0, 100);
    TRACE_INFO("bc2\r\n");

    char b[10];
    int n;
    //while(n = Serial_read(0, b, 10, -1)) {
    while(1) {
        n = Serial_read(0, b, 10, 1000);
        //led.stateToggle();
        //LED_TOGGLE;
        Led_stateToggle(&led);
        if (n) 
            Serial_write(0, b, n, -1);
    }
}

#if 0
void lua( void* p )
{
    (void)p;

    TRACE_INFO("lua\r\n");
    UsbSerial_open();
    while( !UsbSerial_isActive() ) // while usb is not active
        Task_sleep(10);        // wait around for a little bit

    lua_main();

    led_loop();
}
#endif

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


void bcsp( void* p )
{
    (void)p;

    TRACE_INFO("bcsp\r\n");

/*
    // abort handler test
    uint32_t x = *(uint32_t*)1;
    TRACE_INFO("x %x\r\n", x);
*/

    //bcsp_main();
}




