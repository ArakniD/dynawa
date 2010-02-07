#ifndef HCI_H__
#define HCI_H__

/* BCSP channels */
#define HCI_COMMAND_CHANNEL	5
#define HCI_EVENT_CHANNEL	5
#define HCI_ACL_CHANNEL	6

/* HCI command definitions */
#define HCI_OGF_IP					0x1000
#define HCI_COMMAND_READ_BD_ADDR	(HCI_OGF_IP | 0x0009)

/* HCI event codes */
#define HCI_COMMAND_COMPLETE_EVENT	0x0E
#define HCI_COMMAND_STATUS_EVENT	0x0F
#define HCI_HARDWARE_ERROR_EVENT	0x10

#define HCI_CCE_NUM_HCI_COMMAND_PACKETS_OFFSET	2
#define HCI_CCE_COMMAND_OPCODE_LOW_BYTE			3
#define HCI_CCE_COMMAND_OPCODE_HIGH_BYTE		4

#define HCI_CSE_NUM_HCI_COMMAND_PACKETS_OFFSET	3
#define HCI_CSE_COMMAND_OPCODE_LOW_BYTE			4
#define HCI_CSE_COMMAND_OPCODE_HIGH_BYTE		5

#endif /* HCI_H__ */