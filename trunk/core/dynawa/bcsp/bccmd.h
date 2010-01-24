#ifndef BCCMD_H__
#define BCCMD_H__

#define BCCMD_CHANNEL	2

#define BCCMDPDU_STAT_OK    0

#define BCCMDPDU_GETREQ             0
#define BCCMDPDU_GETRESP            1
#define BCCMDPDU_SETREQ             2

#define BCCMDVARID_CHIPVER          0x281a
#define BCCMDVARID_COLD_RESET       0x4001
#define BCCMDVARID_WARM_RESET       0x4002
#define BCCMDVARID_PS               0x7003

#define PSKEY_ANAFREQ               0x1fe
#define PSKEY_BAUDRATE              0x1be

#endif /* BCCMD_H__ */
