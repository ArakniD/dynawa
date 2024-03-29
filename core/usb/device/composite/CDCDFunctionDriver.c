/* ----------------------------------------------------------------------------
 *         ATMEL Microcontroller Software Support 
 * ----------------------------------------------------------------------------
 * Copyright (c) 2008, Atmel Corporation
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the disclaimer below.
 *
 * Atmel's name may not be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * DISCLAIMER: THIS SOFTWARE IS PROVIDED BY ATMEL "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT ARE
 * DISCLAIMED. IN NO EVENT SHALL ATMEL BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * ----------------------------------------------------------------------------
 */

#if defined(usb_CDCAUDIO) || defined(usb_CDCHID) || defined(usb_CDCCDC) || defined(usb_CDCMSD)
//-----------------------------------------------------------------------------
//      Headers
//-----------------------------------------------------------------------------

// GENERAL
#include <debug/trace.h>
//#include <utility/assert.h>
// USB
#include <usb/device/core/USBD.h>
// CDC
#include <usb/common/cdc/CDCLineCoding.h>
#include <usb/common/cdc/CDCGenericRequest.h>
#include <usb/common/cdc/CDCSetControlLineStateRequest.h>

#include "CDCDFunctionDriver.h"
#include "CDCDFunctionDriverDescriptors.h"

//-----------------------------------------------------------------------------
//         Defines
//-----------------------------------------------------------------------------

/// Number of serial ports supported
#if defined(usb_CDCCDC)
#define CDCD_PORT_NUM   2
#else
#define CDCD_PORT_NUM   1
#endif

//-----------------------------------------------------------------------------
//         Types
//-----------------------------------------------------------------------------

/// CDC Serial port struct
typedef struct {

    CDCLineCoding lineCoding;
    unsigned char isCarrierActivated;
    unsigned char epDataIn;
    unsigned char epDataOut;
    unsigned short serialState;

} CDCDSerialPort;

//-----------------------------------------------------------------------------
//         Internal variables
//-----------------------------------------------------------------------------

/// CDCDSerialPort instance
static CDCDSerialPort cdcdSerial[CDCD_PORT_NUM];

//-----------------------------------------------------------------------------
//         Internal functions
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
/// Callback function which should be invoked after the data of a
/// SetLineCoding request has been retrieved. Sends a zero-length packet
/// to the host for acknowledging the request.
//-----------------------------------------------------------------------------
static void CDCD_SetLineCodingCallback()
{
    USBD_Write(0, 0, 0, 0, 0);
}

//-----------------------------------------------------------------------------
/// Return the port index that host send this request for.
//-----------------------------------------------------------------------------
static char CDCD_GetSerialPort(const USBGenericRequest *request)
{
    if (request->wIndex == CDCD_Descriptors_INTERFACENUM0 + 1)      return 0;
  #if CDCD_PORT_NUM > 1
    else if (request->wIndex == CDCD_Descriptors_INTERFACENUM1 + 1) return 1;
  #endif
    return 0xFF;
}

//-----------------------------------------------------------------------------
/// Receives new line coding information from the USB host.
/// \param request Pointer to a USBGenericRequest instance.
//-----------------------------------------------------------------------------
static void CDCD_SetLineCoding(const USBGenericRequest *request)
{
    unsigned char serial;
    serial = CDCD_GetSerialPort(request);

    TRACE_INFO("sLineCoding_%d ", serial);

    USBD_Read(0,
              (void *) &(cdcdSerial[serial].lineCoding),
              sizeof(CDCLineCoding),
              (TransferCallback) CDCD_SetLineCodingCallback,
              0);
}

//-----------------------------------------------------------------------------
/// Sends the current line coding information to the host through Control
/// endpoint 0.
/// \param request Pointer to a USBGenericRequest instance.
//-----------------------------------------------------------------------------
static void CDCD_GetLineCoding(const USBGenericRequest *request)
{
    unsigned char serial;
    serial = CDCD_GetSerialPort(request);

    TRACE_INFO("gLineCoding_%d ", serial);

    USBD_Write(0,
               (void *) &(cdcdSerial[serial].lineCoding),
               sizeof(CDCLineCoding),
               0,
               0);
}

//-----------------------------------------------------------------------------
/// Changes the state of the serial driver according to the information
/// sent by the host via a SetControlLineState request, and acknowledges
/// the request with a zero-length packet.
/// \param request Pointer to a USBGenericRequest instance.
/// \param activateCarrier The active carrier state to set.
/// \param isDTEPresent The DTE status.
//-----------------------------------------------------------------------------
static void CDCD_SetControlLineState(const USBGenericRequest *request,
                                     unsigned char activateCarrier,
                                     unsigned char isDTEPresent)
{
    unsigned char serial;
    serial = CDCD_GetSerialPort(request);

    TRACE_INFO(
              "sControlLineState_%d(%d, %d) ",
              serial,
              activateCarrier,
              isDTEPresent);

    cdcdSerial[serial].isCarrierActivated = activateCarrier;
    USBD_Write(0, 0, 0, 0, 0);
}

//-----------------------------------------------------------------------------
//         Exported functions
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
/// Initializes the USB device CDC serial function driver.
//-----------------------------------------------------------------------------
void CDCDFunctionDriver_Initialize()
{
    unsigned char serial;

    TRACE_INFO("CDCDFunctionDriver_Initialize\n\r");

    for (serial = 0; serial < CDCD_PORT_NUM; serial ++) {

        CDCDSerialPort * pSerial = &cdcdSerial[serial];

        // Initialize Abstract Control Model attributes
        CDCLineCoding_Initialize(&(pSerial->lineCoding),
                                 115200,
                                 CDCLineCoding_ONESTOPBIT,
                                 CDCLineCoding_NOPARITY,
                                 8);
        pSerial->isCarrierActivated = 0;
        pSerial->serialState = 0;
    }
}

//-----------------------------------------------------------------------------
/// Handles CDC/ACM-specific USB requests sent by the host
/// \param request Pointer to a USBGenericRequest instance.
/// \return 0 if the request is Unsupported, 1 if the request handled.
//-----------------------------------------------------------------------------
unsigned char CDCDFunctionDriver_RequestHandler(
    const USBGenericRequest *request)
{
    switch (USBGenericRequest_GetRequest(request)) {

        case CDCGenericRequest_SETLINECODING:
            
            CDCD_SetLineCoding(request);
            break;

        case CDCGenericRequest_GETLINECODING:

            CDCD_GetLineCoding(request);
            break;

        case CDCGenericRequest_SETCONTROLLINESTATE:

            CDCD_SetControlLineState(request,
                CDCSetControlLineStateRequest_ActivateCarrier(request),
                CDCSetControlLineStateRequest_IsDtePresent(request));

            break;

        // Unsupported request
        default:
            return 0;

    }
    return 1;
}

//-----------------------------------------------------------------------------
/// Receives data from the host through the virtual COM port created by
/// the CDC function serial driver. This function behaves like <USBD_Read>.
/// \param Port Port index to receive.
/// \param Pointer to the data buffer to send.
/// \param Size of the data buffer in bytes.
/// \param callback Optional callback function to invoke when the transfer
///        finishes.
/// \param argument Optional argument to the callback function.
/// \return <USBD_STATUS_SUCCESS> if the read operation started normally;
///         otherwise, the corresponding error code.
//-----------------------------------------------------------------------------
unsigned char CDCDSerialDriver_Read(unsigned char port,
                                    void *data,
                                    unsigned int size,
                                    TransferCallback callback,
                                    void *argument)
{
    unsigned char ep = CDCD_Descriptors_DATAOUT0;

  #if CDCD_PORT_NUM > 1
    ep = (port == 0) ?
        CDCD_Descriptors_DATAOUT0 : CDCD_Descriptors_DATAOUT1;
  #endif

    return USBD_Read(ep,
                     data,
                     size,
                     callback,
                     argument);
}

//-----------------------------------------------------------------------------
/// Sends a data buffer through the virtual COM port created by the CDC
/// function serial driver. This function behaves exactly like <USBD_Write>.
/// \param port Port index to receive.
/// \param  data - Pointer to the data buffer to send.
/// \param  size - Size of the data buffer in bytes.
/// \param  callback - Optional callback function to invoke when the transfer
///         finishes.
/// \param  argument - Optional argument to the callback function.
/// \return <USBD_STATUS_SUCCESS> if the write operation started normally;
///         otherwise, the corresponding error code.
//-----------------------------------------------------------------------------
unsigned char CDCDSerialDriver_Write(unsigned char port,
                                     void *data,
                                     unsigned int size,
                                     TransferCallback callback,
                                     void *argument)
{
    unsigned char ep = CDCD_Descriptors_DATAIN0;

  #if CDCD_PORT_NUM > 1
    ep = (port == 0) ?
        CDCD_Descriptors_DATAIN0 : CDCD_Descriptors_DATAIN1;
  #endif

    return USBD_Write(ep,
                      data,
                      size,
                      callback,
                      argument);
}

//------------------------------------------------------------------------------
/// Returns the current status of the RS-232 line.
/// \param port The port number that checked.
//------------------------------------------------------------------------------
unsigned short CDCDSerialDriver_GetSerialState(unsigned char port)
{
    return cdcdSerial[port].serialState;
}

//------------------------------------------------------------------------------
/// Sets the current serial state of the device to the given value.
/// \param port The port number that the port state should be changed.
/// \param serialState  New device state.
//------------------------------------------------------------------------------
void CDCDSerialDriver_SetSerialState(unsigned char port,
                                     unsigned short serialState)
{
    CDCDSerialPort * pPort;
    unsigned char ep = 0;

/* MV
    ASSERT((serialState & 0xFF80) == 0,
           "CDCDSerialDriver_SetSerialState: Bits D7-D15 are reserved!\n\r");
*/

    // If new state is different from previous one, send a notification to the
    // host
    pPort = &cdcdSerial[port];
    if (pPort->serialState != serialState) {

      #if CDCD_PORT_NUM > 1
        ep = (port == 0) ?
            CDCD_Descriptors_NOTIFICATION0 : CDCD_Descriptors_NOTIFICATION1;
      #endif

        pPort->serialState = serialState;
        USBD_Write(ep,
                   &(pPort->serialState),
                   2,
                   0,
                   0);

        // Reset one-time flags
        pPort->serialState &= ~(CDCD_STATE_OVERRUN
                              | CDCD_STATE_PARITY
                              | CDCD_STATE_FRAMING
                              | CDCD_STATE_RINGSIGNAL
                              | CDCD_STATE_BREAK);
    }
}
#endif // (CDC defined)

