/*******************************************************************************

				(C) COPYRIGHT Cambridge Silicon Radio

FILE
				main.c 

DESCRIPTION:
				Main program for (y)abcsp windows test program

REVISION:		$Revision: 1.1.1.1 $ by $Author: ca01 $
*******************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//#include <conio.h>
#include "uSched.h"
#include "SerialCom.h"
#include "abcsp.h"
#include "abcsp_support_functions.h"
#include "hci.h"
#include "bccmd.h"
#include "bc.h"

#include "lwip/pbuf.h"
#include "lwip/mem.h"
#include "lwip/sys.h"
#include "lwbt/hci.h"

#include "debug/trace.h"


/* -------------------- Command line args processing -------------------- */

static unsigned long baudRate = 115200;
//static unsigned long baudRate = 38400;

//#define USART_BAUDRATE_38400
#define USART_BAUDRATE_115200
//#define USART_BAUDRATE_230400
//#define USART_BAUDRATE_460800
//#define USART_BAUDRATE_921600

#if defined(USART_BAUDRATE_38400)
#define USART_BAUDRATE      38400
#define USART_BAUDRATE_CD   0x009d
#elif defined(USART_BAUDRATE_115200)
#define USART_BAUDRATE      115200
#define USART_BAUDRATE_CD   0x01d8
#elif defined(USART_BAUDRATE_230400)
#define USART_BAUDRATE      230400
#define USART_BAUDRATE_CD   0x03b0
#elif defined(USART_BAUDRATE_460800)
#define USART_BAUDRATE      460800
#define USART_BAUDRATE_CD    0x075f
#define USART_CD_FP         0x4
#elif defined(USART_BAUDRATE_921600)
#define USART_BAUDRATE      921600
#define USART_BAUDRATE_CD    0x0ebf
#endif


/* -------------------- The task -------------------- */


typedef struct TransmitQueueEntryStructTag
{
	unsigned channel;
	unsigned reliableFlag;
	MessageBuffer * messageBuffer;
	struct TransmitQueueEntryStructTag * nextQueueEntry;
} TransmitQueueEntry;

static TransmitQueueEntry * transmitQueue;
int NumberOfHciCommands;

void queueMessage(unsigned char channel, unsigned reliableFlag, unsigned length, unsigned char * payload)
{
	MessageBuffer * messageBuffer;
// MV messageBuffer a messageBuffer->buffer freed later by abcsp_txmsg_done()
    TRACE_BT("queueMessage\r\n");
	messageBuffer = (MessageBuffer *) malloc(sizeof(MessageBuffer));
	messageBuffer->length = length;
	messageBuffer->buffer = payload;
	messageBuffer->index = 0;

	if (reliableFlag)
	{
        TRACE_BT("reliable flag on\r\n");
		if (transmitQueue)
		{
			TransmitQueueEntry * searchPtr;

            TRACE_BT("Message queued\r\n");
			for (searchPtr = transmitQueue; searchPtr->nextQueueEntry; searchPtr = searchPtr->nextQueueEntry)
			{
				;
			}
			searchPtr->nextQueueEntry = (TransmitQueueEntry *) malloc(sizeof(TransmitQueueEntry));
			searchPtr = searchPtr->nextQueueEntry;
			searchPtr->nextQueueEntry = NULL;
			searchPtr->channel = channel;
			searchPtr->reliableFlag = reliableFlag;
			searchPtr->messageBuffer = messageBuffer;
		}
		else
		{
            TRACE_BT("abcsp_sendmsg\r\n");
			if (!abcsp_sendmsg(&AbcspInstanceData, messageBuffer, channel, reliableFlag))
			{
                TRACE_BT("Message not delivered, queued\r\n");
				transmitQueue = (TransmitQueueEntry *) malloc(sizeof(TransmitQueueEntry));
				transmitQueue->nextQueueEntry = NULL;
				transmitQueue->channel = channel;
				transmitQueue->reliableFlag = reliableFlag;
				transmitQueue->messageBuffer = messageBuffer;
			}
		}
	}
	else /* unreliable - just send */
	{
		abcsp_sendmsg(&AbcspInstanceData, messageBuffer, channel, reliableFlag);
	}
}

static void pumpInternalMessage(void)
{
    TRACE_BT("pumpInternalMessage\r\n");
	while (transmitQueue)
	{
        TRACE_BT("abcsp_sendmsg\r\n");
		if (abcsp_sendmsg(&AbcspInstanceData, transmitQueue->messageBuffer, transmitQueue->channel, transmitQueue->reliableFlag))
		{
            TRACE_BT("sent. removed from queue\r\n");
			TransmitQueueEntry * tmpPtr;

			tmpPtr = transmitQueue;
			transmitQueue = tmpPtr->nextQueueEntry;

			free(tmpPtr);
		}
		else
		{
			break;
		}
	}
}

void phybusif_output(struct pbuf *p, u16_t len)
{
    /* Send pbuf on UART */
    //LWIP_DEBUGF(PHYBUSIF_DEBUG, ("phybusif_output: Send pbuf on UART\n"));
    
    unsigned char *t = p->payload;
    TRACE_BT("phybusif_output %d %d %d\r\n", len, t[0], t[1]);

    int channel;
    switch (t[0]) {
    case HCI_COMMAND_DATA_PACKET:
        channel = HCI_COMMAND_CHANNEL;
        break;
    case HCI_ACL_DATA_PACKET:
        channel = HCI_ACL_CHANNEL;
        break;
    default:
        TRACE_ERROR("Unknown packet type\r\n");
    }

    len--;
    u8_t *msg = malloc(len);
    if (msg == NULL) {
        TRACE_ERROR("NOMEM\r\n");
    }
    int remain = len;
    struct pbuf *q = p;
    u8_t *b = msg;
    int count = 0;
    while (remain) {
        if (q == NULL) {
            TRACE_ERROR("PBUF=NULL\r\n");
        }
        int offset = count ? 0 : 1; // to ignore payload[0] = packet type

        int chunk_len = q->len - offset;
        TRACE_BT("pbuf len %d\r\n", chunk_len);
        int n = remain > chunk_len ? chunk_len : remain;
        memcpy(b, q->payload + offset, n);
        b += n;
        remain -= n;
        q = q->next;
        count++;
    }
{
/*
    int cmd = ((((uint16) msg[HCI_CSE_COMMAND_OPCODE_HIGH_BYTE]) << 8)
                     | ((uint16) msg[HCI_CSE_COMMAND_OPCODE_LOW_BYTE]));
*/
    int i;
    for(i = 0; i < len; i++) {
        TRACE_BT("%d=%x\r\n", i, msg[i]);
    }
}
    queueMessage(channel, 1, len, msg);
}

void BgIntPump(void)
{
    TRACE_BT("BgIntPump\r\n");

    int more_todo;
// loop by MV
    do {
TRACE_BT("abcsp_pumptxmsgs\r\n");
	    more_todo = abcsp_pumptxmsgs(&AbcspInstanceData);

	    pumpInternalMessage();
    } while (more_todo);
}

static unsigned char cmdIssueCount;

static void initTestTask(void)
{
    TRACE_BT("initTestTask\r\n");
	NumberOfHciCommands = 0;
	cmdIssueCount = 0;
}

static void pumpHandler(void);
static void restartHandler(void);
#define PUMP_INTERVAL	        1000000
#define BT_INTERVAL	            1000000

#if !defined(TCP_TMR_INTERVAL)
#define TCP_TMR_INTERVAL        250
#endif
#define TCP_INTERVAL	        (TCP_TMR_INTERVAL * 1000)

uint16 bc_state = 0;

static void testTask(void)
{
	unsigned char * readBdAddr;

    TRACE_BT("testTask begin\r\n");
	cmdIssueCount++;
	if (cmdIssueCount >= 100)
	{
		//printf(".");
		TRACE_INFO(".");
		cmdIssueCount = 0;
	}

	if (NumberOfHciCommands > 0)
	{
		NumberOfHciCommands--;

        if (bc_state == BC_STATE_READY) {
            readBdAddr = malloc(3);
            readBdAddr[0] = (unsigned char) ((HCI_COMMAND_READ_BD_ADDR) & 0x00FF);
            readBdAddr[1] = (unsigned char) (((HCI_COMMAND_READ_BD_ADDR) >> 8) & 0x00FF);
            readBdAddr[2] = 0;
            queueMessage(HCI_COMMAND_CHANNEL, 1, 3, readBdAddr);
        } else if (bc_state == BC_STATE_STARTED) {
// PS_ANAFREQ
            uint16 *cmd = malloc(sizeof(uint16) * 9);
            cmd[0] = BCCMDPDU_SETREQ;
            cmd[1] = 9;         // number of uint16s in PDU
            cmd[2] = 1;    // value choosen by host
            cmd[3] = BCCMDVARID_PS;
            cmd[4] = BCCMDPDU_STAT_OK;
            cmd[5] = PSKEY_ANAFREQ;
            cmd[6] = 1;         // length
            cmd[7] = 0;         // default store
            cmd[8] = 0x6590;    // value
            TRACE_INFO("SETTING ANAFREQ\r\n");
            queueMessage(BCCMD_CHANNEL, 1, sizeof(uint16) * 9, cmd);
        } else if (bc_state == BC_STATE_ANAFREQ_SET) {
// PS_BAUDRATE
            uint16 *cmd = malloc(sizeof(uint16) * 9);
            cmd[0] = BCCMDPDU_SETREQ;
            cmd[1] = 9;         // number of uint16s in PDU
            cmd[2] = 2;    // value choosen by host
            cmd[3] = BCCMDVARID_PS;
            cmd[4] = BCCMDPDU_STAT_OK;
            cmd[5] = PSKEY_BAUDRATE;
            cmd[6] = 1;         // length
            cmd[7] = 0;         // default store
            //cmd[8] = 0x9d;    // value (divider 38400);
            //cmd[8] = 0x01d8;    // value (divider 115200);
            //cmd[8] = 0x03b0;    // value (divider 230400);
            //cmd[8] = x075f;    // value (divider 460800);
            //cmd[8] = 0x0ebf;    // value (divider 921600);
            cmd[8] = USART_BAUDRATE_CD;    // value (divider);
            TRACE_INFO("SETTING BAUDRATE %d\r\n", USART_BAUDRATE);
            queueMessage(BCCMD_CHANNEL, 1, sizeof(uint16) * 9, cmd);
        } else if (bc_state == BC_STATE_BAUDRATE_SET) {
// warm reset
            uint16 *cmd = malloc(sizeof(uint16) * 9);
            //cmd[0] = 0;         // BCCMDPDU_GETREQ
            cmd[0] = BCCMDPDU_SETREQ;
            cmd[1] = 9;         // number of uint16s in PDU
            cmd[2] = 3;    // value choosen by host
            //cmd[3] = BCCMDVARID_CHIPVER;
            cmd[3] = BCCMDVARID_WARM_RESET;
            cmd[4] = BCCMDPDU_STAT_OK;
            cmd[5] = 0;         // emty
            // cmd[6-8]         // ignored, zero padding
            bc_state = BC_STATE_RESTARTING;
            TRACE_INFO("RESTARTING BC\r\n");
            queueMessage(BCCMD_CHANNEL, 1, sizeof(uint16) * 9, cmd);
            StartTimer(250000, restartHandler);
        }
	}
    TRACE_BT("testTask end\r\n");
}


/* -------------------- The keyboard handler -------------------- */

#define KEYBOARD_SCAN_INTERVAL	250000
#define ESC_KEY					0x1B

static void keyboardHandler(void)
{
	if (_kbhit())
	{
		switch (getch())
		{
			case ESC_KEY:
				printf("\nUser exit...\n");
				TerminateMicroSched();
				break;

			default:
				break;
		}
	}
	StartTimer(KEYBOARD_SCAN_INTERVAL, keyboardHandler);
}

static void pumpHandler(void)
{
    TRACE_INFO("pumpHandler\r\n");
    BgIntPump();
	StartTimer(PUMP_INTERVAL, pumpHandler);
}

static int btiptmr = 0;

static void btHandler(void) {
    l2cap_tmr();
    rfcomm_tmr();
    bt_spp_tmr();

    //ppp_tmr();
    //nat_tmr();

    if(++btiptmr == 5/*sec*/) {
        //  bt_ip_tmr();
        btiptmr = 0;
    }
	StartTimer(BT_INTERVAL, btHandler);
}

static void tcpHandler(void) {
    tcp_tmr();
	StartTimer(TCP_INTERVAL, tcpHandler);
}

static void restartHandler()
{
    TRACE_INFO("BC RESTARTED\r\n");
    bc_state = BC_STATE_READY;
    Serial_setBaud(0, USART_BAUDRATE); 
    abcsp_init(&AbcspInstanceData);
#if defined(TCPIP)
    //echo_init();
    httpd_init();
#endif
    bt_spp_start();
    TRACE_INFO("Applications started.\r\n");
#if defined(TCPIP)
    StartTimer(TCP_INTERVAL, tcpHandler);
#endif
    StartTimer(BT_INTERVAL, btHandler);
}


/* -------------------- MAIN -------------------- */

#include <board.h>
volatile AT91PS_PIO  pPIOB = AT91C_BASE_PIOB;
volatile AT91PS_PIO  pPIOA = AT91C_BASE_PIOA;

int bcsp_main()
{
    TRACE_BT("bcsp_main\r\n");

    // TODO sys_init();
#ifdef PERF
    perf_init("/tmp/minimal.perf");
#endif /* PERF */
#ifdef STATS
    stats_init();
#endif /* STATS */
    mem_init();
    memp_init();
    pbuf_init();
    TRACE_INFO("mem mgmt initialized\r\n");


#if defined(TCPIP)
    netif_init();
    ip_init();
    //udp_init();
    tcp_init();
    printf("TCP/IP initialized.\n");
#endif
    lwbt_memp_init();
    //phybusif_init(argv[1]);
    if(hci_init() != ERR_OK) {
        TRACE_ERROR("HCI initialization failed!\r\n");
        return -1;
    }
    l2cap_init();
    sdp_init();
    rfcomm_init();
#if defined(TCPIP)
    ppp_init();
#endif
    TRACE_INFO("Bluetooth initialized.\r\n");




	InitMicroSched(initTestTask, testTask);

	UartDrv_RegisterHandlers();
	UartDrv_Configure(baudRate);

/* BC4
-BCRES - PB30
BCBOOT0 - PB23 -> BC4 PIO0
BCBOOT1 - PB25 -> BC4 PIO1
BCBOOT2 - PB29 -> BC4 PIO4

PIO[0]
PIO[1]
PIO[4]
Host Transport
Auto System Clock Adaptation
Auto Baud Rate Adaptation
0
0
0
BCSP (default) (a)
Available (b)
Available (c)
0
0
1
BCSP with UART configured to use 2 stop bits and no parity
Available (b)
Available (c)
0
1
0
USB, 16 MHz crystal (d)
Not available
Not appropriate
0
1
1
USB, 26 MHz crystal (d)
Not available
Not appropriate
1
0
0
Three-wire UART
Available (b)
Available (c)
1
0
1
H4DS
Available (b)
Available (c)
1
1
0
UART (H4)
Available (b)
Available (c)
1
1
1
Undefined
-
-

Petr: takze nejprve drzet v resetu a potom nastavit piny BCBOOT0:2 na jaky protokol ma BC naject, pak -BCRES do 1
*/
#define BCBOOT0_MASK (1 << 23)
#define BCBOOT1_MASK (1 << 25)
#define BCBOOT2_MASK (1 << 29)
#define BCNRES_MASK (1 << 30)

    pPIOB->PIO_PER = BCBOOT0_MASK;
    pPIOB->PIO_OER = BCBOOT0_MASK;
    pPIOB->PIO_CODR = BCBOOT0_MASK; //set to log0

    pPIOB->PIO_PER = BCBOOT1_MASK;
    pPIOB->PIO_OER = BCBOOT1_MASK;                                         
    pPIOB->PIO_CODR = BCBOOT1_MASK; //set to log0

    pPIOB->PIO_PER = BCBOOT2_MASK;
    pPIOB->PIO_OER = BCBOOT2_MASK;
    pPIOB->PIO_CODR = BCBOOT2_MASK; //set to log0

    TRACE_INFO("B_PIO_ODSR %x\r\n", pPIOB->PIO_ODSR);

    pPIOB->PIO_PER = BCNRES_MASK;
    pPIOB->PIO_OER = BCNRES_MASK;
    pPIOB->PIO_CODR = BCNRES_MASK; //set to log0

    TRACE_INFO("B_PIO_ODSR %x\r\n", pPIOB->PIO_ODSR);
    TRACE_INFO("B_PIO_PSR %x\r\n", pPIOB->PIO_PSR);

    Task_sleep(20);
/*
    pPIOB->PIO_SODR = BCNRES_MASK;
    Task_sleep(20);
    pPIOB->PIO_CODR = BCNRES_MASK; //set to log0
    Task_sleep(20);
*/
    pPIOB->PIO_SODR = BCNRES_MASK;
    TRACE_INFO("B_PIO_ODSR %x\r\n", pPIOB->PIO_ODSR);

    Task_sleep(10);
    bc_state = BC_STATE_STARTED;

 
    if (!UartDrv_Start())
    {
        TerminateMicroSched();
    } else {
        TRACE_INFO("A_PIO_OSR %x\r\n", pPIOA->PIO_OSR);
        //StartTimer(KEYBOARD_SCAN_INTERVAL, keyboardHandler);
	    abcsp_init(&AbcspInstanceData);
        //StartTimer(PUMP_INTERVAL, pumpHandler);
        MicroSched();
        UartDrv_Stop();
    }

	return 0;
}
