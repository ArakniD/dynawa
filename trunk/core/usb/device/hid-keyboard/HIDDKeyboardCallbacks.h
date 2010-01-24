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

/*
    Title: HIDDKeyboardCallbacks

    About: Purpose
        Definitions of callbacks used by the HID keyboard device driver to
        notify the application of events.

    About: Usage
        1 - Re-implement any number of these callbacks anywhere in the program;
            they will be called automatically by the driver when the related
            event occurs.
*/

#ifndef HIDDKEYBOARDCALLBACKS_H
#define HIDDKEYBOARDCALLBACKS_H

//------------------------------------------------------------------------------
//         Exported functions
//------------------------------------------------------------------------------
/*
    Function: HIDDKeyboardCallbacks_LedsChanged
        Indicates that the status of one or more LEDs has been changed by the
        host.

    Parameters:
        numLockStatus - Indicates the current status of the num. lock key.
        capsLockStatus - Indicates the current status of the caps lock key.
        scrollLockStatus - Indicates the current status of the scroll lock key.
*/
extern void HIDDKeyboardCallbacks_LedsChanged(unsigned char numLockStatus,
                                              unsigned char capsLockStatus,
                                              unsigned char scrollLockStatus);

#endif //#ifndef HIDDKEYBOARDCALLBACKS_H

