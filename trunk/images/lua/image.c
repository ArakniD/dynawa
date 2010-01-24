/*
	make.c
	
	make.c is the main project file.  The Run( ) task gets called on bootup, so stick any initialization stuff in there.
	In Heavy, by default we set the USB, OSC, and Network systems active, but you don't need to if you aren't using them.
	Furthermore, only register the OSC subsystems you need - by default, we register all of them.
*/

#include "core.h"
#include "led.h"
//#include "appled.h"
#include <debug/trace.h>
//#include "serial.h"
#include <rtos.h>
#include <usbserial.h>
#include <serial.h>

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

void blinkLoop( void* parameters );
void console( void* parameters );
void bc( void* parameters );
void lua( void* parameters );
void lua_event_loop( void* parameters );
void usb( void* parameters );
void usb_msd( void* parameters );
void bcsp( void* parameters );

void panic(void) {
    TRACE_ERROR("!!!PANIC!!!\r\n");
    while(1);
}

void Run( ) // this task gets called as soon as we boot up.
{
  //TRACE_INFO("Run\n\r");
  //System* sys = System::get();
  //int free_mem = sys->freeMemory();

  //Task_create( blinkLoop, "Blink", 400, 1, NULL );
  Task_create( console, "console", 400, 1, NULL );
  //Task_create( bc, "BlueCore", 400, 1, NULL );
#if defined(USB_COMPOSITE)
  //Task_create( usb, "USB", 1024, 1, NULL );
#else
  //Task_create( lua, "LUA", 8192, 1, NULL );
#endif
  Task_create( lua_event_loop, "LUA_Event_loop", 8192, 1, NULL );
  //monitorTaskStart();

  // MV bcsp task requires higher pri??? why?
  Task_create( bcsp, "BCSP", 16000, 2, NULL );

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
    vTaskSuspend( NULL );
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

  UsbSerial_init();
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
      UsbSerial_write(b, n);
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
  Serial_init(0, 100);
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

void lua( void* p )
{
  (void)p;

  TRACE_INFO("lua\r\n");
  UsbSerial_init();
  while( !UsbSerial_isActive() ) // while usb is not active
    Task_sleep(10);        // wait around for a little bit

  lua_main();

  led_loop();
}

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
  UsbSerial_init();
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

  bcsp_main();
}




