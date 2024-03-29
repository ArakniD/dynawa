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

//------------------------------------------------------------------------------
//         Headers
//------------------------------------------------------------------------------

#include "CDCDSerialDriverDescriptors.h"
#include <board.h>
// #include <usb/common/core/USBGenericDescriptor.h>
#include "USBGenericDescriptor.h"
// #include <usb/common/core/USBConfigurationDescriptor.h>
#include "USBConfigurationDescriptor.h"
// #include <usb/common/core/USBEndpointDescriptor.h>
#include "USBEndpointDescriptor.h"
// #include <usb/common/core/USBStringDescriptor.h>
#include "USBStringDescriptor.h"
// #include <usb/common/core/USBGenericRequest.h>
#include "USBGenericRequest.h"
// #include <usb/common/cdc/CDCGenericDescriptor.h>
#include "CDCGenericDescriptor.h"
// #include <usb/common/cdc/CDCDeviceDescriptor.h>
#include "CDCDeviceDescriptor.h"
// #include <usb/common/cdc/CDCCommunicationInterfaceDescriptor.h>
#include "CDCCommunicationInterfaceDescriptor.h"
// #include <usb/common/cdc/CDCDataInterfaceDescriptor.h>
#include "CDCDataInterfaceDescriptor.h"
// #include <usb/common/cdc/CDCHeaderDescriptor.h>
#include "CDCHeaderDescriptor.h"
// #include <usb/common/cdc/CDCCallManagementDescriptor.h>
#include "CDCCallManagementDescriptor.h"
// #include <usb/common/cdc/CDCAbstractControlManagementDescriptor.h>
#include "CDCAbstractControlManagementDescriptor.h"
// #include <usb/common/cdc/CDCUnionDescriptor.h>
#include "CDCUnionDescriptor.h"

//------------------------------------------------------------------------------
//         Definitions
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// \page "CDC Serial Device IDs"
/// This page lists the IDs used in the CDC Serial Device Descriptor.
///
/// !IDs
/// - CDCDSerialDriverDescriptors_PRODUCTID
/// - CDCDSerialDriverDescriptors_VENDORID
/// - CDCDSerialDriverDescriptors_RELEASE

/// Device product ID.
#define CDCDSerialDriverDescriptors_PRODUCTID       0x0920

/// Device vendor ID (Atmel).
#define CDCDSerialDriverDescriptors_VENDORID        0xEB03

/// Device release number.
#define CDCDSerialDriverDescriptors_RELEASE         0x0100
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//         Macros
//------------------------------------------------------------------------------

/// Returns the minimum between two values.
#define MIN(a, b)       ((a < b) ? a : b)

//------------------------------------------------------------------------------
//         Internal structures
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// Configuration descriptor list for a device implementing a CDC serial driver.
//------------------------------------------------------------------------------
typedef struct {

    /// Standard configuration descriptor.
    USBConfigurationDescriptor configuration;
    /// Communication interface descriptor.
    USBInterfaceDescriptor  communication;
    /// CDC header functional descriptor.
    CDCHeaderDescriptor header;
    /// CDC call management functional descriptor.
    CDCCallManagementDescriptor callManagement;
    /// CDC abstract control management functional descriptor.
    CDCAbstractControlManagementDescriptor abstractControlManagement;
    /// CDC union functional descriptor (with one slave interface).
    CDCUnionDescriptor union1;
    /// Notification endpoint descriptor.
    USBEndpointDescriptor notification;
    /// Data interface descriptor.
    USBInterfaceDescriptor data;
    /// Data OUT endpoint descriptor.
    USBEndpointDescriptor dataOut;
    /// Data IN endpoint descriptor.
    USBEndpointDescriptor dataIn;

} __attribute__ ((packed)) CDCDSerialDriverConfigurationDescriptors;

//------------------------------------------------------------------------------
//         Exported variables
//------------------------------------------------------------------------------

/// Standard USB device descriptor for the CDC serial driver
const USBDeviceDescriptor deviceDescriptor = {

    sizeof(USBDeviceDescriptor),
    USBGenericDescriptor_DEVICE,
    USBDeviceDescriptor_USB2_00,
    CDCDeviceDescriptor_CLASS,
    CDCDeviceDescriptor_SUBCLASS,
    CDCDeviceDescriptor_PROTOCOL,
    BOARD_USB_ENDPOINTS_MAXPACKETSIZE(0),
    CDCDSerialDriverDescriptors_VENDORID,
    CDCDSerialDriverDescriptors_PRODUCTID,
    CDCDSerialDriverDescriptors_RELEASE,
    2, // Index of manufacturer string descriptor is #2
    1, // Index of product string descriptor is #1
    0, // No string descriptor for serial number
    1 // Device has 1 possible configuration
};

#if defined(BOARD_USB_UDPHS)

/// USB device qualifier descriptor.
const USBDeviceQualifierDescriptor qualifierDescriptor = {

    sizeof(USBDeviceQualifierDescriptor),
    USBGenericDescriptor_DEVICEQUALIFIER,
    USBDeviceDescriptor_USB2_00,
    CDCDeviceDescriptor_CLASS,
    CDCDeviceDescriptor_SUBCLASS,
    CDCDeviceDescriptor_PROTOCOL,
    BOARD_USB_ENDPOINTS_MAXPACKETSIZE(0),
    1, // Device has one possible configuration
    0 // Reserved
};

#endif

/// Standard USB configuration descriptor for the CDC serial driver
const CDCDSerialDriverConfigurationDescriptors configurationDescriptors = {

    // Standard configuration descriptor
    {
        sizeof(USBConfigurationDescriptor),
        USBGenericDescriptor_CONFIGURATION,
        sizeof(CDCDSerialDriverConfigurationDescriptors),
        2, // There are two interfaces in this configuration
        1, // This is configuration #1
        0, // No string descriptor for this configuration
        BOARD_USB_BMATTRIBUTES,
        USBConfigurationDescriptor_POWER(100)
    },
    // Communication class interface standard descriptor
    {
        sizeof(USBInterfaceDescriptor),
        USBGenericDescriptor_INTERFACE,
        0, // This is interface #0
        0, // This is alternate setting #0 for this interface
        1, // This interface uses 1 endpoint
        CDCCommunicationInterfaceDescriptor_CLASS,
        CDCCommunicationInterfaceDescriptor_ABSTRACTCONTROLMODEL,
        CDCCommunicationInterfaceDescriptor_NOPROTOCOL,
        0  // No string descriptor for this interface
    },
    // Class-specific header functional descriptor
    {
        sizeof(CDCHeaderDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_HEADER,
        CDCGenericDescriptor_CDC1_10
    },
    // Class-specific call management functional descriptor
    {
        sizeof(CDCCallManagementDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_CALLMANAGEMENT,
        CDCCallManagementDescriptor_SELFCALLMANAGEMENT,
//        0 // No associated data interface
        0xFF // required for OS X to provide a serial port entry
    },
    // Class-specific abstract control management functional descriptor
    {
        sizeof(CDCAbstractControlManagementDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_ABSTRACTCONTROLMANAGEMENT,
        CDCAbstractControlManagementDescriptor_LINE
    },
    // Class-specific union functional descriptor with one slave interface
    {
        sizeof(CDCUnionDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_UNION,
        0, // Number of master interface is #0
        1 // First slave interface is #1
    },
    // Notification endpoint standard descriptor
    {
        sizeof(USBEndpointDescriptor), 
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_IN,
                                      CDCDSerialDriverDescriptors_NOTIFICATION),
        USBEndpointDescriptor_INTERRUPT,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_NOTIFICATION),
            USBEndpointDescriptor_MAXINTERRUPTSIZE_FS),
        10 // Endpoint is polled every 10ms
    },
    // Data class interface standard descriptor
    {
        sizeof(USBInterfaceDescriptor),
        USBGenericDescriptor_INTERFACE,
        1, // This is interface #1
        0, // This is alternate setting #0 for this interface
        2, // This interface uses 2 endpoints
        CDCDataInterfaceDescriptor_CLASS,
        CDCDataInterfaceDescriptor_SUBCLASS,
        CDCDataInterfaceDescriptor_NOPROTOCOL,
        0  // No string descriptor for this interface
    },
    // Bulk-OUT endpoint standard descriptor
    {
        sizeof(USBEndpointDescriptor), 
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_OUT,
                                      CDCDSerialDriverDescriptors_DATAOUT),
        USBEndpointDescriptor_BULK,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_DATAOUT),
            USBEndpointDescriptor_MAXBULKSIZE_FS),
        0 // Must be 0 for full-speed bulk endpoints
    },
    // Bulk-IN endpoint descriptor
    {
        sizeof(USBEndpointDescriptor),
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_IN,
                                      CDCDSerialDriverDescriptors_DATAIN),
        USBEndpointDescriptor_BULK,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_DATAIN),
            USBEndpointDescriptor_MAXBULKSIZE_FS),
        0 // Must be 0 for full-speed bulk endpoints
    },
};

/// Language ID string descriptor
const unsigned char languageIdStringDescriptor[] = {

    USBStringDescriptor_LENGTH(1),
    USBGenericDescriptor_STRING,
    USBStringDescriptor_ENGLISH_US
};

#if defined(BOARD_USB_UDPHS)
/// Other-speed configuration descriptor (when in full-speed).
const CDCDSerialDriverConfigurationDescriptors otherSpeedDescriptorsFS = {

    // Standard configuration descriptor
    {
        sizeof(USBConfigurationDescriptor),
        USBGenericDescriptor_OTHERSPEEDCONFIGURATION,
        sizeof(CDCDSerialDriverConfigurationDescriptors),
        2, // There are two interfaces in this configuration
        1, // This is configuration #1
        0, // No string descriptor for this configuration
        BOARD_USB_BMATTRIBUTES,
        USBConfigurationDescriptor_POWER(100)
    },
    // Communication class interface standard descriptor
    {
        sizeof(USBInterfaceDescriptor),
        USBGenericDescriptor_INTERFACE,
        0, // This is interface #0
        0, // This is alternate setting #0 for this interface
        1, // This interface uses 1 endpoint
        CDCCommunicationInterfaceDescriptor_CLASS,
        CDCCommunicationInterfaceDescriptor_ABSTRACTCONTROLMODEL,
        CDCCommunicationInterfaceDescriptor_NOPROTOCOL,
        0  // No string descriptor for this interface
    },
    // Class-specific header functional descriptor
    {
        sizeof(CDCHeaderDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_HEADER,
        CDCGenericDescriptor_CDC1_10
    },
    // Class-specific call management functional descriptor
    {
        sizeof(CDCCallManagementDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_CALLMANAGEMENT,
        CDCCallManagementDescriptor_SELFCALLMANAGEMENT,
        0 // No associated data interface
    },
    // Class-specific abstract control management functional descriptor
    {
        sizeof(CDCAbstractControlManagementDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_ABSTRACTCONTROLMANAGEMENT,
        CDCAbstractControlManagementDescriptor_LINE
    },
    // Class-specific union functional descriptor with one slave interface
    {
        sizeof(CDCUnionDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_UNION,
        0, // Number of master interface is #0
        1 // First slave interface is #1
    },
    // Notification endpoint standard descriptor
    {
        sizeof(USBEndpointDescriptor), 
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_IN,
                                      CDCDSerialDriverDescriptors_NOTIFICATION),
        USBEndpointDescriptor_INTERRUPT,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_NOTIFICATION),
            USBEndpointDescriptor_MAXINTERRUPTSIZE_HS),
        10 // Endpoint is polled every 10ms
    },
    // Data class interface standard descriptor
    {
        sizeof(USBInterfaceDescriptor),
        USBGenericDescriptor_INTERFACE,
        1, // This is interface #1
        0, // This is alternate setting #0 for this interface
        2, // This interface uses 2 endpoints
        CDCDataInterfaceDescriptor_CLASS,
        CDCDataInterfaceDescriptor_SUBCLASS,
        CDCDataInterfaceDescriptor_NOPROTOCOL,
        0  // No string descriptor for this interface
    },
    // Bulk-OUT endpoint standard descriptor
    {
        sizeof(USBEndpointDescriptor), 
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_OUT,
                                      CDCDSerialDriverDescriptors_DATAOUT),
        USBEndpointDescriptor_BULK,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_DATAOUT),
            USBEndpointDescriptor_MAXBULKSIZE_HS),
        0 // Must be 0 for full-speed bulk endpoints
    },
    // Bulk-IN endpoint descriptor
    {
        sizeof(USBEndpointDescriptor),
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_IN,
                                      CDCDSerialDriverDescriptors_DATAIN),
        USBEndpointDescriptor_BULK,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_DATAIN),
            USBEndpointDescriptor_MAXBULKSIZE_HS),
        0 // Must be 0 for full-speed bulk endpoints
    },
};


/// Configuration descriptor (when in high-speed).
const CDCDSerialDriverConfigurationDescriptors configurationDescriptorsHS = {

    // Standard configuration descriptor
    {
        sizeof(USBConfigurationDescriptor),
        USBGenericDescriptor_CONFIGURATION,
        sizeof(CDCDSerialDriverConfigurationDescriptors),
        2, // There are two interfaces in this configuration
        1, // This is configuration #1
        0, // No string descriptor for this configuration
        BOARD_USB_BMATTRIBUTES,
        USBConfigurationDescriptor_POWER(100)
    },
    // Communication class interface standard descriptor
    {
        sizeof(USBInterfaceDescriptor),
        USBGenericDescriptor_INTERFACE,
        0, // This is interface #0
        0, // This is alternate setting #0 for this interface
        1, // This interface uses 1 endpoint
        CDCCommunicationInterfaceDescriptor_CLASS,
        CDCCommunicationInterfaceDescriptor_ABSTRACTCONTROLMODEL,
        CDCCommunicationInterfaceDescriptor_NOPROTOCOL,
        0  // No string descriptor for this interface
    },
    // Class-specific header functional descriptor
    {
        sizeof(CDCHeaderDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_HEADER,
        CDCGenericDescriptor_CDC1_10
    },
    // Class-specific call management functional descriptor
    {
        sizeof(CDCCallManagementDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_CALLMANAGEMENT,
        CDCCallManagementDescriptor_SELFCALLMANAGEMENT,
        0 // No associated data interface
    },
    // Class-specific abstract control management functional descriptor
    {
        sizeof(CDCAbstractControlManagementDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_ABSTRACTCONTROLMANAGEMENT,
        CDCAbstractControlManagementDescriptor_LINE
    },
    // Class-specific union functional descriptor with one slave interface
    {
        sizeof(CDCUnionDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_UNION,
        0, // Number of master interface is #0
        1 // First slave interface is #1
    },
    // Notification endpoint standard descriptor
    {
        sizeof(USBEndpointDescriptor), 
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_IN,
                                      CDCDSerialDriverDescriptors_NOTIFICATION),
        USBEndpointDescriptor_INTERRUPT,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_NOTIFICATION),
            USBEndpointDescriptor_MAXINTERRUPTSIZE_HS),
        10 // Endpoint is polled every 10ms
    },
    // Data class interface standard descriptor
    {
        sizeof(USBInterfaceDescriptor),
        USBGenericDescriptor_INTERFACE,
        1, // This is interface #1
        0, // This is alternate setting #0 for this interface
        2, // This interface uses 2 endpoints
        CDCDataInterfaceDescriptor_CLASS,
        CDCDataInterfaceDescriptor_SUBCLASS,
        CDCDataInterfaceDescriptor_NOPROTOCOL,
        0  // No string descriptor for this interface
    },
    // Bulk-OUT endpoint standard descriptor
    {
        sizeof(USBEndpointDescriptor), 
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_OUT,
                                      CDCDSerialDriverDescriptors_DATAOUT),
        USBEndpointDescriptor_BULK,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_DATAOUT),
            USBEndpointDescriptor_MAXBULKSIZE_HS),
        0 // Must be 0 for full-speed bulk endpoints
    },
    // Bulk-IN endpoint descriptor
    {
        sizeof(USBEndpointDescriptor),
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_IN,
                                      CDCDSerialDriverDescriptors_DATAIN),
        USBEndpointDescriptor_BULK,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_DATAIN),
            USBEndpointDescriptor_MAXBULKSIZE_HS),
        0 // Must be 0 for full-speed bulk endpoints
    },
};

/// Other-speed configuration descriptor (when in high-speed).
const CDCDSerialDriverConfigurationDescriptors otherSpeedDescriptorsHS = {

    // Standard configuration descriptor
    {
        sizeof(USBConfigurationDescriptor),
        USBGenericDescriptor_OTHERSPEEDCONFIGURATION,
        sizeof(CDCDSerialDriverConfigurationDescriptors),
        2, // There are two interfaces in this configuration
        1, // This is configuration #1
        0, // No string descriptor for this configuration
        BOARD_USB_BMATTRIBUTES,
        USBConfigurationDescriptor_POWER(100)
    },
    // Communication class interface standard descriptor
    {
        sizeof(USBInterfaceDescriptor),
        USBGenericDescriptor_INTERFACE,
        0, // This is interface #0
        0, // This is alternate setting #0 for this interface
        1, // This interface uses 1 endpoint
        CDCCommunicationInterfaceDescriptor_CLASS,
        CDCCommunicationInterfaceDescriptor_ABSTRACTCONTROLMODEL,
        CDCCommunicationInterfaceDescriptor_NOPROTOCOL,
        0  // No string descriptor for this interface
    },
    // Class-specific header functional descriptor
    {
        sizeof(CDCHeaderDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_HEADER,
        CDCGenericDescriptor_CDC1_10
    },
    // Class-specific call management functional descriptor
    {
        sizeof(CDCCallManagementDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_CALLMANAGEMENT,
        CDCCallManagementDescriptor_SELFCALLMANAGEMENT,
        0 // No associated data interface
    },
    // Class-specific abstract control management functional descriptor
    {
        sizeof(CDCAbstractControlManagementDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_ABSTRACTCONTROLMANAGEMENT,
        CDCAbstractControlManagementDescriptor_LINE
    },
    // Class-specific union functional descriptor with one slave interface
    {
        sizeof(CDCUnionDescriptor),
        CDCGenericDescriptor_INTERFACE,
        CDCGenericDescriptor_UNION,
        0, // Number of master interface is #0
        1 // First slave interface is #1
    },
    // Notification endpoint standard descriptor
    {
        sizeof(USBEndpointDescriptor), 
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_IN,
                                      CDCDSerialDriverDescriptors_NOTIFICATION),
        USBEndpointDescriptor_INTERRUPT,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_NOTIFICATION),
            USBEndpointDescriptor_MAXINTERRUPTSIZE_FS),
        10 // Endpoint is polled every 10ms
    },
    // Data class interface standard descriptor
    {
        sizeof(USBInterfaceDescriptor),
        USBGenericDescriptor_INTERFACE,
        1, // This is interface #1
        0, // This is alternate setting #0 for this interface
        2, // This interface uses 2 endpoints
        CDCDataInterfaceDescriptor_CLASS,
        CDCDataInterfaceDescriptor_SUBCLASS,
        CDCDataInterfaceDescriptor_NOPROTOCOL,
        0  // No string descriptor for this interface
    },
    // Bulk-OUT endpoint standard descriptor
    {
        sizeof(USBEndpointDescriptor), 
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_OUT,
                                      CDCDSerialDriverDescriptors_DATAOUT),
        USBEndpointDescriptor_BULK,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_DATAOUT),
            USBEndpointDescriptor_MAXBULKSIZE_FS),
        0 // Must be 0 for full-speed bulk endpoints
    },
    // Bulk-IN endpoint descriptor
    {
        sizeof(USBEndpointDescriptor),
        USBGenericDescriptor_ENDPOINT,
        USBEndpointDescriptor_ADDRESS(USBEndpointDescriptor_IN,
                                      CDCDSerialDriverDescriptors_DATAIN),
        USBEndpointDescriptor_BULK,
        MIN(BOARD_USB_ENDPOINTS_MAXPACKETSIZE(CDCDSerialDriverDescriptors_DATAIN),
            USBEndpointDescriptor_MAXBULKSIZE_FS),
        0 // Must be 0 for full-speed bulk endpoints
    },
};
#endif

/// Product string descriptor
const unsigned char productStringDescriptor[] = {

    USBStringDescriptor_LENGTH(10),
    USBGenericDescriptor_STRING,
    USBStringDescriptor_UNICODE('D'),
    USBStringDescriptor_UNICODE('y'),
    USBStringDescriptor_UNICODE('n'),
    USBStringDescriptor_UNICODE('a'),
    USBStringDescriptor_UNICODE('w'),
    USBStringDescriptor_UNICODE('a'),
    USBStringDescriptor_UNICODE(' '),
    USBStringDescriptor_UNICODE('T'),
    USBStringDescriptor_UNICODE('C'),
    USBStringDescriptor_UNICODE('H'),
};

// Manufacturer string descriptor
const unsigned char manufacturerStringDescriptor[] = {

    USBStringDescriptor_LENGTH(6),
    USBGenericDescriptor_STRING,
    USBStringDescriptor_UNICODE('D'),
    USBStringDescriptor_UNICODE('y'),
    USBStringDescriptor_UNICODE('n'),
    USBStringDescriptor_UNICODE('a'),
    USBStringDescriptor_UNICODE('w'),
    USBStringDescriptor_UNICODE('a')
};

/// List of string descriptors used by the device
const unsigned char *stringDescriptors[] = {

    languageIdStringDescriptor,
    productStringDescriptor,
    manufacturerStringDescriptor
};

/// List of standard descriptors for the serial driver.
USBDDriverDescriptors cdcdSerialDriverDescriptors = {

    &deviceDescriptor,
    (USBConfigurationDescriptor *) &(configurationDescriptors),
#ifdef BOARD_USB_UDPHS
    &qualifierDescriptor,
    (USBConfigurationDescriptor *) &(otherSpeedDescriptorsFS),
    &deviceDescriptor,
    (USBConfigurationDescriptor *) &(configurationDescriptorsHS),
    &qualifierDescriptor,
    (USBConfigurationDescriptor *) &(otherSpeedDescriptorsHS),
#else
    0, // No full-speed device qualifier descriptor
    0, // No full-speed other speed configuration
    0, // No high-speed device descriptor
    0, // No high-speed configuration descriptor
    0, // No high-speed device qualifier descriptor
    0, // No high-speed other speed configuration descriptor

#endif
    stringDescriptors,
    2 // 2 string descriptors in list
};

