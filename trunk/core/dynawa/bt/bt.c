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
#include "rtos.h"

#include "lwip/pbuf.h"
#include "lwip/mem.h"
#include "lwip/sys.h"
#include "lwbt/hci.h"
#include "lwbt/rfcomm.h"
#include "bt.h"
#include "event.h"

#include "debug/trace.h"


#define SET_HOST_WAKE       1

#define SET_TX_POWER        0
#define TX_POWER            2

#define BT_COMMAND_QUEUE_LEN 10

uint32_t bc_hci_event_count;
static Task bt_task_handle;
static xQueueHandle command_queue;

static unsigned int bt_open_count = 0;

/* -------------------- Command line args processing -------------------- */

static unsigned long baudRate = 460800;
//static unsigned long baudRate = 115200;
//static unsigned long baudRate = 38400;

//#define USART_BAUDRATE_38400
//#define USART_BAUDRATE_115200
//#define USART_BAUDRATE_230400
//#define USART_BAUDRATE_460800
#define USART_BAUDRATE_921600

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
        panic();
        return;
    }
    // TODO: pbuf2buf()
    int remain = len;
    struct pbuf *q = p;
    u8_t *b = msg;
    int count = 0;
    while (remain) {
        if (q == NULL) {
            TRACE_ERROR("PBUF=NULL\r\n");
            panic();
            return;
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
    // MV } while (0);
}

static unsigned char cmdIssueCount;

static void u_init_bt_task(void)
{
    TRACE_BT("u_init_bt_task\r\n");
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

static void u_bt_task(bt_command *cmd)
{
	unsigned char * readBdAddr;

    TRACE_BT("u_bt_task begin\r\n");

    if (cmd) {
        switch(cmd->id) {
        case BT_COMMAND_STOP:
            // TODO: stop all BT connections
            TerminateMicroSched();
            break;
        case BT_COMMAND_SEND:
            {
                TRACE_INFO("BT_COMMAND_SEND\r\n");
                bt_socket *sock = cmd->sock;
                struct pbuf *p = cmd->param.ptr;

                _bt_rfcomm_send(sock, p);

                pbuf_free(p);
            }
            break;
        case BT_COMMAND_SET_LINK_KEY:
            {
                TRACE_INFO("BT_COMMAND_SET_LINK_KEY\r\n");
                struct bt_bdaddr_link_key *bdaddr_link_key = cmd->param.ptr;

                hci_write_stored_link_key(&bdaddr_link_key->bdaddr, &bdaddr_link_key->link_key);

                free(bdaddr_link_key);
            }
            break;
        case BT_COMMAND_RFCOMM_LISTEN:
            {
                TRACE_INFO("BT_COMMAND_RFCOMM_LISTEN\r\n");
                bt_socket *sock = cmd->sock;

                _bt_rfcomm_listen(sock, cmd->param.cn);
            }
            break;
        case BT_COMMAND_RFCOMM_CONNECT:
            {
                TRACE_INFO("BT_COMMAND_RFCOMM_CONNECT\r\n");
                bt_socket *sock = cmd->sock;
                struct bt_bdaddr_cn *bdaddr_cn = cmd->param.ptr;

                _bt_rfcomm_connect(sock, &bdaddr_cn->bdaddr, bdaddr_cn->cn);

                free(bdaddr_cn);
            }
            break;
        case BT_COMMAND_FIND_SERVICE:
            {
                TRACE_INFO("BT_COMMAND_FIND_SERVICE\r\n");
                bt_socket *sock = cmd->sock;
                struct bd_addr *bdaddr = cmd->param.ptr;

                sock->current_cmd = cmd->id;
                _bt_find_service(sock, bdaddr);

                free(bdaddr);
            }
            break;
        case BT_COMMAND_INQUIRY:
            {
                TRACE_INFO("BT_COMMAND_INQUIRY\r\n");
                _bt_inquiry();
            }
            break;
        }
    }

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
#if SET_HOST_WAKE
        } else if (bc_state == BC_STATE_BAUDRATE_SET) {
// PS_UART_HOST_WAKE_SIGNAL 
            uint16 *cmd = malloc(sizeof(uint16) * 9);
            cmd[0] = BCCMDPDU_SETREQ;
            cmd[1] = 9;         // number of uint16s in PDU
            cmd[2] = 2;    // value choosen by host
            cmd[3] = BCCMDVARID_PS;
            cmd[4] = BCCMDPDU_STAT_OK;
            cmd[5] = PSKEY_UART_HOST_WAKE_SIGNAL;
            cmd[6] = 1;         // length
            cmd[7] = 0;         // default store
            //cmd[8] = 3;       // enabled
            cmd[8] = 0;         // disabled
            TRACE_INFO("SETTING UART_HOST_WAKE_SIGNAL\r\n");
            queueMessage(BCCMD_CHANNEL, 1, sizeof(uint16) * 9, cmd);
        } else if (bc_state == BC_STATE_UART_HOST_WAKE_SIGNAL) {
// PS_UART_HOST_WAKE
            uint16 *cmd = malloc(sizeof(uint16) * 12);
            cmd[0] = BCCMDPDU_SETREQ;
            cmd[1] = 12;         // number of uint16s in PDU
            cmd[2] = 2;    // value choosen by host
            cmd[3] = BCCMDVARID_PS;
            cmd[4] = BCCMDPDU_STAT_OK;
            cmd[5] = PSKEY_UART_HOST_WAKE;
            cmd[6] = 1;         // length
            cmd[7] = 0;         // default store
            cmd[8] = 0x0001;         // enable
            cmd[9] = 0x01f4;    // sleep timeout = 500ms
            cmd[10] = 0x0005;   // break len = 5ms
            cmd[11] = 0x0020;   // pause length = 32ms
            TRACE_INFO("SETTING UART_HOST_WAKE\r\n");
            queueMessage(BCCMD_CHANNEL, 1, sizeof(uint16) * 12, cmd);
        } else if (bc_state == BC_STATE_UART_HOST_WAKE) {
#else
        } else if (bc_state == BC_STATE_BAUDRATE_SET) {
#endif
/*
#if SET_TX_POWER
        } else if (bc_state == BC_STATE_BAUDRATE_SET) {
// PS_LC_MAX_TX_POWER
            uint16 *cmd = malloc(sizeof(uint16) * 9);
            cmd[0] = BCCMDPDU_SETREQ;
            cmd[1] = 9;         // number of uint16s in PDU
            cmd[2] = 2;    // value choosen by host
            cmd[3] = BCCMDVARID_PS;
            cmd[4] = BCCMDPDU_STAT_OK;
            cmd[5] = PSKEY_LC_MAX_TX_POWER;
            cmd[6] = 1;         // length
            cmd[7] = 0;         // default store
            cmd[8] = TX_POWER;
            TRACE_INFO("SETTING LC_MAX_TX_POWER\r\n");
            queueMessage(BCCMD_CHANNEL, 1, sizeof(uint16) * 9, cmd);
        } else if (bc_state == BC_STATE_LC_MAX_TX_POWER) {
// PS_LC_DEFAULT_TX_POWER
            uint16 *cmd = malloc(sizeof(uint16) * 9);
            cmd[0] = BCCMDPDU_SETREQ;
            cmd[1] = 9;         // number of uint16s in PDU
            cmd[2] = 2;    // value choosen by host
            cmd[3] = BCCMDVARID_PS;
            cmd[4] = BCCMDPDU_STAT_OK;
            cmd[5] = PSKEY_LC_DEFAULT_TX_POWER;
            cmd[6] = 1;         // length
            cmd[7] = 0;         // default store
            cmd[8] = TX_POWER;
            TRACE_INFO("SETTING LC_DEFAULT_TX_POWER\r\n");
            queueMessage(BCCMD_CHANNEL, 1, sizeof(uint16) * 9, cmd);
        } else if (bc_state == BC_STATE_LC_DEFAULT_TX_POWER) {
// PS_LC_MAX_TX_POWER_NO_RSSI
            uint16 *cmd = malloc(sizeof(uint16) * 9);
            cmd[0] = BCCMDPDU_SETREQ;
            cmd[1] = 9;         // number of uint16s in PDU
            cmd[2] = 2;    // value choosen by host
            cmd[3] = BCCMDVARID_PS;
            cmd[4] = BCCMDPDU_STAT_OK;
            cmd[5] = PSKEY_LC_MAX_TX_POWER_NO_RSSI;
            cmd[6] = 1;         // length
            cmd[7] = 0;         // default store
            cmd[8] = TX_POWER;
            TRACE_INFO("SETTING LC_MAX_TX_POWER_NO_RSSI\r\n");
            queueMessage(BCCMD_CHANNEL, 1, sizeof(uint16) * 9, cmd);
        } else if (bc_state == BC_STATE_LC_MAX_TX_POWER_NO_RSSI) {
#else
        } else if (bc_state == BC_STATE_BAUDRATE_SET) {
#endif
*/
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
    TRACE_BT("u_bt_task end\r\n");
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
    bc_hci_event_count = 0;
    Serial_setBaud(0, USART_BAUDRATE); 
    abcsp_init(&AbcspInstanceData);
#if defined(TCPIP)
    //echo_init();
    httpd_init();
#endif
    bt_spp_start();
    TRACE_INFO("Applications started.\r\n");

/*
    event ev;
    ev.type = EVENT_BT;
    ev.data.bt.type = EVENT_BT_STARTED;
    event_post(&ev);
*/

#if defined(TCPIP)
    StartTimer(TCP_INTERVAL, tcpHandler);
#endif
    StartTimer(BT_INTERVAL, btHandler);
}


/* -------------------- MAIN -------------------- */

#include <board.h>
volatile AT91PS_PIO  pPIOB = AT91C_BASE_PIOB;
volatile AT91PS_PIO  pPIOA = AT91C_BASE_PIOA;

void bt_task(void *p)
//int bcsp_main()
{
    TRACE_BT("bt_task %x\r\n", xTaskGetCurrentTaskHandle());

    ledrgb_open();
    ledrgb_set(0x4, 0, 0, BT_LED_HIGH);

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
    TRACE_INFO("TCP/IP initialized.\r\n");
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

	InitMicroSched(u_init_bt_task, u_bt_task);

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
#define BCBOOT0_MASK (1 << 23)  // BC4 PIO0
#define BCBOOT1_MASK (1 << 25)  // BC4 PIO1
#define BCBOOT2_MASK (1 << 29)  // BC4 PIO4
#define BCNRES_MASK (1 << 30)

/*
//MV CTS/RTS
    pPIOA->PIO_PDR = (1 << 7);
    pPIOA->PIO_PDR = (1 << 8);
*/

    pPIOB->PIO_PER = BCBOOT0_MASK;
    pPIOB->PIO_OER = BCBOOT0_MASK;
    pPIOB->PIO_CODR = BCBOOT0_MASK; //set to log0

    pPIOB->PIO_PER = BCBOOT1_MASK;
    pPIOB->PIO_OER = BCBOOT1_MASK;                                         
    pPIOB->PIO_CODR = BCBOOT1_MASK; //set to log0

    pPIOB->PIO_PER = BCBOOT2_MASK;
    pPIOB->PIO_OER = BCBOOT2_MASK;
    pPIOB->PIO_CODR = BCBOOT2_MASK; //set to log0

    //TRACE_INFO("B_PIO_ODSR %x\r\n", pPIOB->PIO_ODSR);

    pPIOB->PIO_PER = BCNRES_MASK;
    pPIOB->PIO_OER = BCNRES_MASK;
    pPIOB->PIO_CODR = BCNRES_MASK; //set to log0

    //TRACE_INFO("B_PIO_ODSR %x\r\n", pPIOB->PIO_ODSR);
    //TRACE_INFO("B_PIO_PSR %x\r\n", pPIOB->PIO_PSR);

    Task_sleep(20);
/*
    pPIOB->PIO_SODR = BCNRES_MASK;
    Task_sleep(20);
    pPIOB->PIO_CODR = BCNRES_MASK; //set to log0
    Task_sleep(20);
*/
    pPIOB->PIO_SODR = BCNRES_MASK; // Run BC, run!
    //TRACE_INFO("B_PIO_ODSR %x\r\n", pPIOB->PIO_ODSR);

    Task_sleep(10);
    bc_state = BC_STATE_STARTED;

    TRACE_BT("BC restarted\r\n");
 
    if (!UartDrv_Start())
    {
        TerminateMicroSched();
    } else {
        //TRACE_INFO("A_PIO_OSR %x\r\n", pPIOA->PIO_OSR);
        //StartTimer(KEYBOARD_SCAN_INTERVAL, keyboardHandler);
	    abcsp_init(&AbcspInstanceData);
        //StartTimer(PUMP_INTERVAL, pumpHandler);
        MicroSched();
        UartDrv_Stop();
        CloseMicroSched();
    }

    pPIOB->PIO_CODR = BCNRES_MASK; // BC Stop
    bc_state = BC_STATE_STOPPED;

    event ev;
    ev.type = EVENT_BT;
    ev.data.bt.type = EVENT_BT_STOPPED;
    event_post(&ev);

    ledrgb_set(0x4, 0, 0, 0x0);
    ledrgb_close();
    vTaskDelete(NULL);
}

bool bt_get_command(bt_command *cmd) {
    return xQueueReceive(command_queue, cmd, 0);
}


void bt_stop_callback() {
    vQueueDelete(command_queue);
}

uint16_t bt_buf_len(struct pbuf *p) {
    return p->len;
}

void *bt_buf_payload(struct pbuf *p) {
    return p->payload;
}

void bt_buf_free(struct pbuf *p) {
    pbuf_free(p);
}

void trace_bytes(char *text, uint8_t *bytes, int len) {
    int i;
    for (i = 0; i < len; i++) {
        TRACE_INFO("%s[%d] = %02x\r\n", text, i, bytes[i]);
    }
}

// commands 

int bt_init() {
    bc_state = BC_STATE_STOPPED;
    return 0;
}

int bt_open() {

    if(!bt_open_count++) {
        command_queue = xQueueCreate(BT_COMMAND_QUEUE_LEN, sizeof(bt_command));
        //bt_task_handle = Task_create( bt_task, "bt_main", TASK_BT_MAIN_STACK, TASK_BT_MAIN_PRI, NULL );
        xTaskCreate(bt_task, "bt_main", TASK_STACK_SIZE(TASK_BT_MAIN_STACK), TASK_BT_MAIN_PRI, NULL, &bt_task_handle);
        return BT_OK;
    }
    return BT_ERR_ALREADY_STARTED;
}

int bt_close() {

    if(bt_open_count && --bt_open_count == 0) {
        bt_command cmd;

        if (bt_task_handle == NULL) {
            return BT_OK;
        }
        cmd.id = BT_COMMAND_STOP;

        xQueueSend(command_queue, &cmd, portMAX_DELAY);
        scheduler_wakeup();
    }
    return BT_OK;
}

void bt_set_link_key(uint8_t *bdaddr, uint8_t *link_key) {
    bt_command cmd;

    TRACE_INFO("bt_set_link_key\r\n");

    struct bt_bdaddr_link_key *bdaddr_link_key = malloc(sizeof(struct bt_bdaddr_link_key)); 
    if (bdaddr_link_key == NULL) {
        return BT_ERR_MEM;
    }
    memcpy(&bdaddr_link_key->bdaddr, bdaddr, BT_BDADDR_LEN);
    memcpy(&bdaddr_link_key->link_key, link_key, BT_LINK_KEY_LEN);

    trace_bytes("bdaddr", bdaddr, BT_BDADDR_LEN);
    trace_bytes("linkkey", link_key, BT_LINK_KEY_LEN);

    cmd.id = BT_COMMAND_SET_LINK_KEY;
    cmd.param.ptr = bdaddr_link_key;

    xQueueSend(command_queue, &cmd, portMAX_DELAY);
    scheduler_wakeup();
    return BT_OK;
}

void bt_inquiry() {
    bt_command cmd;

    TRACE_INFO("bt_inquiry\r\n");

    cmd.id = BT_COMMAND_INQUIRY;

    xQueueSend(command_queue, &cmd, portMAX_DELAY);
    scheduler_wakeup();
    return BT_OK;
}

// socket commands

void bt_rfcomm_listen(bt_socket *sock, uint8_t channel) {
    bt_command cmd;

    TRACE_INFO("bt_rfcomm_listen %x %d\r\n", sock, channel);

    cmd.id = BT_COMMAND_RFCOMM_LISTEN;
    cmd.sock = sock;
    cmd.param.cn = channel;

    xQueueSend(command_queue, &cmd, portMAX_DELAY);
    scheduler_wakeup();
    return BT_OK;
}

void bt_rfcomm_connect(bt_socket *sock, uint8_t *bdaddr, uint8_t channel) {
    bt_command cmd;

    TRACE_INFO("bt_rfcomm_connect %x %d\r\n", sock, channel);

    struct bt_bdaddr_cn *bdaddr_cn = malloc(sizeof(struct bt_bdaddr_cn)); 
    if (bdaddr_cn == NULL) {
        return BT_ERR_MEM;
    }
    memcpy(&bdaddr_cn->bdaddr, bdaddr, BT_BDADDR_LEN);
    bdaddr_cn->cn = channel;

    trace_bytes("bdaddr", bdaddr, BT_BDADDR_LEN);

    cmd.id = BT_COMMAND_RFCOMM_CONNECT;
    cmd.sock = sock;
    cmd.param.ptr = bdaddr_cn;

    xQueueSend(command_queue, &cmd, portMAX_DELAY);
    scheduler_wakeup();
    return BT_OK;
}

void bt_find_service(bt_socket *sock, uint8_t *bdaddr) {
    bt_command cmd;

    TRACE_INFO("bt_find_service %x\r\n", sock);

    struct bd_addr *cmd_bdaddr = malloc(sizeof(struct bd_addr)); 
    if (cmd_bdaddr == NULL) {
        return BT_ERR_MEM;
    }
    memcpy(cmd_bdaddr, bdaddr, BT_BDADDR_LEN);

    trace_bytes("bdaddr", bdaddr, BT_BDADDR_LEN);

    cmd.id = BT_COMMAND_FIND_SERVICE;
    cmd.sock = sock;
    cmd.param.ptr = cmd_bdaddr;

    xQueueSend(command_queue, &cmd, portMAX_DELAY);
    scheduler_wakeup();
    return BT_OK;
}

int bt_rfcomm_send(bt_socket *sock, const char *data) {
    bt_command cmd;
    struct pbuf *p;

    uint16_t len = strlen(data) + 1;
    
    TRACE_INFO("bt_rfcomm_send %s %d\r\n", data, len);
    p = pbuf_alloc(PBUF_RAW, len, PBUF_RAM);
    if (p == NULL) {
        return BT_ERR_MEM;
    }
    strcpy(p->payload, data);

    cmd.id = BT_COMMAND_SEND;
    cmd.sock = sock;
    cmd.param.ptr = p;

    xQueueSend(command_queue, &cmd, portMAX_DELAY);
    scheduler_wakeup();
    return BT_OK;
}
