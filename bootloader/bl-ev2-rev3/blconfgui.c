/* ========================================================================== */
/*                                                                            */
/*   Filename.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */


// main menu:
//
//  Dynawa BL Conf:
//  
//  Image
//  Power btn
//  Reset btn
//  POST
//  Hw Stats


#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "hardware_conf.h"
#include "firmware_conf.h"
#include "board_lowlevel.h"
#include <utils/macros.h>

#include <screen/screen.h>
#include <screen/font.h>

#include <debug/trace.h>
//#include <utils/interrupt_utils.h>
#include <utils/time.h>
#include <peripherals/serial.h>
#include <utils/delay.h>
#include <peripherals/pmc/pmc.h>
#include <peripherals/spi.h>
#include <utils/rprintf.h>

#include <microgui/ugscrdrv.h>
#include <microgui/microgui.h>
#include <peripherals/oled/oled.h>
#include <sdcard/sdcard.h>
//#include <fat/fat.h>
#include <fatfs/ff.h>

#include "blconfgui.h"
#include "nvmrc.h"

FATFS  fatfs;  
FIL bootrecord;

char buff[40];
UINT bread, r; 



//common components:
tugui_Btn comBtnCancel;
const char* ini_comBtnName="Cancel";
// Main window:
tugui_Win winMain;
//tugui_Listbox winMainListbox;
tugui_Label winMainTitle;
tugui_Label winMainUpBtnLab;
tugui_Label winMainDnBtnLab;
tugui_Listbox winMainMenu;
const char* ini_winMainTitle="Dynawa TCH1 Setup";
const char* ini_winMainUpBtnLab="UP";
const char* ini_winMainDnBtnLab="DN";
const char* mainmenu[]={"Image load .bin","Screen,boot MSD/Image","Buttons Power ON/OFF","Buttons HW Reset","POST Configuration","HW Status","- SAVE & EXIT -","- EXIT & Discard -"};
typedef char filename_t[32];
filename_t sfilelist[16];//={"main1.bin","main2.bin","main3.bin"};
char * filelist[16];//={"main1.bin","main2.bin","main3.bin"};
char bootname[32];
//tugui_ListboxItems ;

//Image list window:
tugui_Win winImage;
tugui_Listbox winImageListbox;
tugui_Label winImageTitle;
tugui_Label winImageFile;
const char* ini_winImageTitle="Select Image File";
//const char* ini_winImageFile="file_name";

//btns power/reset list window:
tugui_Win winBtns;
tugui_Label winBtnsTitle;
tugui_Listbox winBtnListbox;
const char* btnlist[]={"Letf Up","Left Middle","Left Down","Right Down","Right Up","Delay Time"};
const char* btnproplist[]={"?","?","?","?","?","?"};
const char* ini_NotAvail="N/A"; 
//const char* btnproplistP[]={"YES","-  ","YES","-  ","-  "};
const char* ini_winBtnRTitle="Reset Buttons";
const char* ini_winBtnPTitle="Power On/Off Btns";

//screen/boot:
tugui_Win winMisc;
tugui_Label winMiscTitle;
tugui_Listbox winMiscListbox;
const char* misclist[]={"Screen rotate","Boot default"};
//const char* ScrMsdProplist[]={"?","?","?","?","?","?"}; 
const char* miscproplist[]={"YES","MSD"};
const char* proplistMSD[]={"Image","USB MSD"};
const char* ini_winMiscTitle="Misc. configuration";


//POST configuration
tugui_Win winPost;
tugui_Label winPostTitle;
tugui_Listbox winPostListbox;
const char* postlist[]={"SRAM","RTC","Gas Gauge","Accelerometer","LED Driver"};
const char* postproplist[]={"YES","YES","YES","YES","NO "};
const char* ini_winPostTitle="Process POST on:";

//HW Stats
tugui_Win winStat;
tugui_Label winStatTitle;
const char* ini_winStatTitle="HW Status:";

//edit properties window with listbox
tugui_Win winEProp;
//tugui_Label winBtnsTitle;
tugui_Listbox winEPropListbox;
const char* proplist[]={"NO","YES"};
const char* proplistT[]={"0.5sec","1sec","1.5sec","2sec","2.5sec","3sec","3.5sec","4sec"};

//edit properties window with listbox
tugui_Win winQry;
//tugui_Label winBtnsTitle;
tugui_Listbox winQryListbox;
tugui_Label winQryTitle;
const char* ini_winQrySaveExit="Realy SAVE & EXIT ?";
const char* ini_winQryExit="Really discard changes ?";
const char* qrylist[]={"Cancel","Yes"};

tugui_Plain winHWstatWrite;

#define LENproplistT 8

#define MAIN_MENU_IMAGE 0
#define MAIN_MENU_MISC 1
#define MAIN_MENU_PWRBTN 2
#define MAIN_MENU_RSTBTN 3
#define MAIN_MENU_POST 4
#define MAIN_MENU_HWSTAT 5
#define MAIN_MENU_SAVEEXIT 6
#define MAIN_MENU_EXIT 7
#define QRY_YES 1
#define QRY_CANCEL 0

void searchImages(void);

int winMainSelectCallback(void *p)
{
  uint8_t i;
   TRACE_ALL("@main select callback ");
  switch (winMainMenu.itemi)
  {
    case MAIN_MENU_IMAGE: { winImageFile.label = bootname; uguiContextSwitch(1); break;}
    case MAIN_MENU_MISC: {
      
      if (blconf.screenRotate<=1) winMiscListbox.props[0]=proplist[blconf.screenRotate];
      if (blconf.defMSDBoot<=1) winMiscListbox.props[1]=proplistMSD[blconf.defMSDBoot];
      uguiContextSwitch(7); break;
    }
    case MAIN_MENU_PWRBTN: { 
      //load conf data:
      for (i=0;i<5;i++)
      {
        if (blconf.pwrBtns[i]<=1)
          winBtnListbox.props[i]=proplist[blconf.pwrBtns[i]];
        else
          winBtnListbox.props[i]=ini_NotAvail;  
      }  
      if (blconf.pwrDelay<=8) winBtnListbox.props[5]=proplistT[blconf.pwrDelay];
      winBtnsTitle.label=ini_winBtnPTitle; 
      uguiContextSwitch(2); 
      break; 
    }
    case MAIN_MENU_RSTBTN: { 
      //load conf data:
      for (i=0;i<5;i++)
      {
        if (blconf.rstBtns[i]<=1)
          winBtnListbox.props[i]=proplist[blconf.rstBtns[i]];
        else
          winBtnListbox.props[i]=ini_NotAvail;  
      }  
      if (blconf.rstDelay<=8) winBtnListbox.props[5]=proplistT[blconf.rstDelay];
      winBtnsTitle.label=ini_winBtnRTitle; 
      uguiContextSwitch(2); 
      break; 
    }
    case MAIN_MENU_POST: {      
      if (blconf.POST_sram<=1) winPostListbox.props[0]=proplist[blconf.POST_sram];
      if (blconf.POST_rtc<=1) winPostListbox.props[1]=proplist[blconf.POST_rtc]; 
      if (blconf.POST_gasgauge<=1) winPostListbox.props[2]=proplist[blconf.POST_gasgauge];
      if (blconf.POST_accel<=1) winPostListbox.props[3]=proplist[blconf.POST_accel];  
      if (blconf.POST_led<=1) winPostListbox.props[4]=proplist[blconf.POST_led];
      uguiContextSwitch(3); break; 
    }
    case MAIN_MENU_HWSTAT: { uguiContextSwitch(5); break; } //hw stats
    case MAIN_MENU_SAVEEXIT: {
      winQryTitle.label=ini_winQrySaveExit;
      uguiContextSwitch(6);       
      break;
    }
    case MAIN_MENU_EXIT: {
      winQryTitle.label=ini_winQryExit;      
      uguiContextSwitch(6);       
      break;
    }
    default: break;
  } 
  
  return 0;
}

int winImageSelectCallback(void *p)
{
  TRACE_ALL("@image select callback ");
  winImageFile.label = winImageListbox.items[winImageListbox.itemi]; 
  uguiLabel(&winImageFile,UGUI_EV_REDRAW);
   
  fontSetCharPos(5,90);
  if ((r=f_open(&bootrecord, "boot", FA_WRITE))== FR_OK)
  {
    strncpy(buff,winImageFile.label,31);
    if ((r=f_write(&bootrecord,buff,31,&bread))== FR_OK)
    {           
      TRACE_SCR("written.");
          
    } else {TRACE_SCR("f_read boot e:%d\n\r",r);}
    
    f_close(&bootrecord);
  } else {TRACE_SCR("f_open boot e:%d\n\r",r);}
  //uguiContextSwitch(0);
  return 0;
}

int winMiscSelectCallback(void *p)
{
  TRACE_ALL("@misc select callback ");
  if (winMiscListbox.itemi==0)
  {
    winEPropListbox.itemi=0;
    winEPropListbox.items=proplist; //ptr to arry of charptr(strings yes/no)  
    winEPropListbox.itemn=2; //no of items in listbox labels        
  } else {
    winEPropListbox.itemi=0;
    winEPropListbox.items=proplistMSD; //ptr to arry of charptr(strings)  
    winEPropListbox.itemn=2; //no of items in listbox labels
  }
  uguiContextSwitch(4);
  return 0;
}


int winBtnSelectCallback(void *p)
{
  TRACE_ALL("@btn select callback ");
  if (winBtnListbox.itemi==5)
  {
    winEPropListbox.itemi=0;
    winEPropListbox.items=proplistT; //ptr to arry of charptr(strings)  
    winEPropListbox.itemn=LENproplistT; //no of items in listbox labels
  } else {
    winEPropListbox.itemi=0;
    winEPropListbox.items=proplist; //ptr to arry of charptr(strings)  
    winEPropListbox.itemn=2; //no of items in listbox labels
  }
  uguiContextSwitch(4);
  return 0;
}

int winPostSelectCallback(void *p)
{
  TRACE_ALL("@btn select callback ");
  winEPropListbox.itemi=0;
  winEPropListbox.items=proplist; //ptr to arry of charptr(strings)  
  winEPropListbox.itemn=2; //no of items in listbox labels
  uguiContextSwitch(4);
  return 0;
}

int winCancelBtnCallback(void *p)
{
  TRACE_ALL("@cancel btn callback ");  
  uguiContextSwitch(0);
  return 0;
}

int winEPropSelectCallback(void *p)
{
  TRACE_ALL("@epropsel btn callback ");
  //switch (uguiLastContext())
  switch (winMainMenu.itemi)
  {
    case MAIN_MENU_MISC://Power btns
    {       
      if (winMiscListbox.itemi==0)
      {      
        winMiscListbox.props[winMiscListbox.itemi]=proplist[winEPropListbox.itemi];
        blconf.screenRotate = winEPropListbox.itemi;
      }  
      if (winMiscListbox.itemi==1)
      {     
        winMiscListbox.props[winMiscListbox.itemi]=proplistMSD[winEPropListbox.itemi];
        blconf.defMSDBoot=winEPropListbox.itemi;
      }
      break;
    } 
    case MAIN_MENU_PWRBTN://Power btns
    {       
      if (winBtnListbox.itemi==5)
      {      
        winBtnListbox.props[winBtnListbox.itemi]=proplistT[winEPropListbox.itemi];
        blconf.pwrDelay = winEPropListbox.itemi;
      } else {     
        winBtnListbox.props[winBtnListbox.itemi]=proplist[winEPropListbox.itemi];
        blconf.pwrBtns[winBtnListbox.itemi]=winEPropListbox.itemi;
      }
      break;
    } 
    case MAIN_MENU_RSTBTN://Reset btns
    {    
      if (winBtnListbox.itemi==5)
      {      
        winBtnListbox.props[winBtnListbox.itemi]=proplistT[winEPropListbox.itemi];
        blconf.rstDelay = winEPropListbox.itemi;
      } else {             
        winBtnListbox.props[winBtnListbox.itemi]=proplist[winEPropListbox.itemi];
        blconf.rstBtns[winBtnListbox.itemi]=winEPropListbox.itemi;
      }  
      break;
    } 
    case  MAIN_MENU_POST://POST 
    {      
      winPostListbox.props[winPostListbox.itemi]=proplist[winEPropListbox.itemi];
      switch (winPostListbox.itemi)
      {
        case 0: blconf.POST_sram = winEPropListbox.itemi; break;
        case 1: blconf.POST_rtc = winEPropListbox.itemi; break;
        case 2: blconf.POST_gasgauge = winEPropListbox.itemi; break;
        case 3: blconf.POST_accel = winEPropListbox.itemi; break;
        case 4: blconf.POST_led = winEPropListbox.itemi; break; 
      }
      break;
    }
  
  }
  uguiContextSwitch(uguiLastContext());
  return 0;
}


//Qry window callback:
int winQrySelectCallback(void *p)
{
  if (winQryListbox.itemi==QRY_CANCEL) uguiContextSwitch(0);
  if ((winQryListbox.itemi==QRY_YES)&&(winMainMenu.itemi==MAIN_MENU_EXIT)) resetByRstCtrl();//RSTC_reset();
  if ((winQryListbox.itemi==QRY_YES)&&(winMainMenu.itemi==MAIN_MENU_SAVEEXIT))
  {
    writeSetupConf();
    resetByRstCtrl();//RSTC_reset();
  } 
  
  
  return 0;
}


//plain object for HW status print:
tugui_Event uguiPrintHWstat(tugui_Plain *plain, tugui_Event evt)
{
   int x;
   switch (evt)
   {
     //mandatory events:
     case UGUI_EV_REDRAW:
     {
       x=fontCarridgeReturnPosX;
       fontCarridgeReturnPosX=plain->x;
       fontSetCharPos(plain->x,plain->y);
       TRACE_SCR("ID:0x%x\n\r",getUID());         
       TRACE_SCR("Memory: PSRAM 64Mbit\n\r");
       TRACE_SCR("SDcard: 2GB\n\r"); //!!TODO
       TRACE_SCR("Battery voltage:%d mV\n\r",getBatVoltage());
       TRACE_SCR("Time xx/xx/xxxx --:--:--\n\r");
       fontCarridgeReturnPosX=x;
     }
   }  
   return 0;
}

void blConfGuiInit(void)
{
  uguiInitContext();
  
  //common:
  if (blconf.screenRotate)
  {
    comBtnCancel.x=123;
  } else {
    comBtnCancel.x=0;
  }  
  comBtnCancel.y=120;comBtnCancel.w=36;comBtnCancel.h=8;
  comBtnCancel.label = ini_comBtnName;
  comBtnCancel.releaseCallback=NULL;
  comBtnCancel.pushCallback= &winCancelBtnCallback;
  comBtnCancel.pushEvent=102;
  comBtnCancel.releaseEvent=0;
  comBtnCancel.fgColor=0xff;
  comBtnCancel.bgColor=0x0;
  comBtnCancel.fgColorPushed=0xff;
  comBtnCancel.bgColorPushed=0xffffff;
  comBtnCancel.font=UGD_FONT6x8;
  comBtnCancel.bitmapw=0;comBtnCancel.bitmaph=0;
  comBtnCancel.bitmap=NULL; 
 
  winMainTitle.x=12; winMainTitle.y=12; winMainTitle.h=10; winMainTitle.w=100;
  winMainTitle.label=ini_winMainTitle; winMainTitle.font=UGD_FONT6x8; 
  winMainTitle.fgColor=0xffffff;
  winMainTitle.bgColor=0;
  //
  if (blconf.screenRotate)
  {
    winMainUpBtnLab.x=0;
  } else {
    winMainUpBtnLab.x=148;
  }  
  winMainUpBtnLab.y=0;winMainUpBtnLab.h=8;winMainUpBtnLab.w=12;
  winMainUpBtnLab.label=ini_winMainUpBtnLab;winMainUpBtnLab.font=UGD_FONT6x8;
  winMainUpBtnLab.fgColor=0x444444;
  winMainUpBtnLab.bgColor=0x0000;
  //
  if (blconf.screenRotate)
  {
    winMainDnBtnLab.x=0;
  } else {
    winMainDnBtnLab.x=148;
  }  
  winMainDnBtnLab.y=120;winMainDnBtnLab.h=8;winMainDnBtnLab.w=12;
  winMainDnBtnLab.label=ini_winMainDnBtnLab;winMainDnBtnLab.font=UGD_FONT6x8;
  winMainDnBtnLab.fgColor=0x444444;
  winMainDnBtnLab.bgColor=0x0000;
  //
  winMainMenu.x=10; winMainMenu.y=30; winMainMenu.h=8; winMainMenu.w=1;
  winMainMenu.itemw=140;  winMainMenu.itemh=10;
  winMainMenu.label=NULL;
  winMainMenu.items=mainmenu; //ptr to arry of charptr(strings)
  winMainMenu.props=NULL;
  winMainMenu.itemn=8; //no of items in listbox labels
  winMainMenu.itemi=0;   
  winMainMenu.flow=0;
  winMainMenu.scrollDnEvent=200;
  winMainMenu.scrollUpEvent=201;
  winMainMenu.selectEvent=202;
  winMainMenu.scrollDnCallback=NULL;//&boxDnCallback;
  winMainMenu.scrollUpCallback=NULL;//&boxDnCallback;
  winMainMenu.selectCallback=&winMainSelectCallback;//&boxSelectCallback; 
  winMainMenu.fgColor=0xffffff;
  winMainMenu.bgColor=0xaa0000;   
  winMainMenu.fgColorSelected=0xffffff;
  winMainMenu.bgColorSelected=0xaa;
  
  //
  winMain.x=0;winMain.y=0;winMain.w=OLED_RESOLUTION_X-1;winMain.h=OLED_RESOLUTION_Y-1;
  winMain.bgColor=0;
  winMain.fgColor=0xaa0000;  
  winMain.objn=0;
  winMain.attr = UGUI_WINATTR_DRAWFRAME;//
  //
  uguiWinAddObj(&winMain,&winMainMenu,&uguiListbox);
  uguiWinAddObj(&winMain,&winMainDnBtnLab,&uguiLabel);
  uguiWinAddObj(&winMain,&winMainUpBtnLab,&uguiLabel);
  uguiWinAddObj(&winMain,&winMainTitle,&uguiLabel);
  uguiWinAddObj(&winMain,&comBtnCancel,&uguiBtn);
  
  
  
  //  win Image select:--------------------------------
  winImageTitle.x=12; winImageTitle.y=12; winImageTitle.h=10; winImageTitle.w=30;
  winImageTitle.label=ini_winImageTitle;winImageTitle.font=UGD_FONT6x8;
  winImageTitle.fgColor=0xffffff;
  winImageTitle.bgColor=0x000;
  
  winImageFile.x=4; winImageFile.y=100; winImageFile.h=10; winImageFile.w=145;
  bootname[0]='?';bootname[1]=0;
  winImageFile.label=bootname;//ini_winImageFile; 
  winImageFile.font=UGD_FONT6x8;
  winImageFile.fgColor=0x0;
  winImageFile.bgColor=0xffffff;
  
  winImageListbox.x=3;winImageListbox.y=30;winImageListbox.w=1;winImageListbox.h=6;
  winImageListbox.itemw=154;  winImageListbox.itemh=9;
  winImageListbox.label=NULL;
  winImageListbox.items=filelist; //ptr to arry of charptr(strings)
  winImageListbox.props=NULL;
  winImageListbox.itemn=0; //no of items in listbox labels
  winImageListbox.itemi=0;   
  winImageListbox.flow=0;
  winImageListbox.font = UGD_FONT6x8;
  winImageListbox.scrollDnEvent=200;
  winImageListbox.scrollUpEvent=201;
  winImageListbox.selectEvent=202;
  winImageListbox.scrollDnCallback=NULL;//&boxDnCallback;
  winImageListbox.scrollUpCallback=NULL;//&boxDnCallback;
  winImageListbox.selectCallback=&winImageSelectCallback;//&boxSelectCallback; 
  winImageListbox.fgColor=0xffffff;
  winImageListbox.bgColor=0xaa0000;   
  winImageListbox.fgColorSelected=0xffffff;
  winImageListbox.bgColorSelected=0xaa;
  
  winImage.x=0;winImage.y=0;winImage.w=OLED_RESOLUTION_X-1;winImage.h=OLED_RESOLUTION_Y-1;
  winImage.bgColor=0x0000;  
  winImage.objn=0;
  winImage.fgColor=0xaa0000;  
  winImage.attr = UGUI_WINATTR_DRAWFRAME;//
  
  uguiWinAddObj(&winImage,&winImageListbox,&uguiListbox);
  uguiWinAddObj(&winImage,&winImageTitle,&uguiLabel);  
  uguiWinAddObj(&winImage,&winImageFile,&uguiLabel);
  uguiWinAddObj(&winImage,&winMainDnBtnLab,&uguiLabel);
  uguiWinAddObj(&winImage,&winMainUpBtnLab,&uguiLabel);
  uguiWinAddObj(&winImage,&comBtnCancel,&uguiBtn);
  
  //property editor
  winEPropListbox.x=40;winEPropListbox.y=48;winEPropListbox.w=1;winEPropListbox.h=2;
  winEPropListbox.itemw=80;  winEPropListbox.itemh=11;
  winEPropListbox.label=NULL;
  winEPropListbox.items=proplist; //ptr to arry of charptr(strings)
  winEPropListbox.props=NULL;
  winEPropListbox.itemn=2; //no of items in listbox labels
  winEPropListbox.itemi=0;   
  winEPropListbox.flow=0;
  winEPropListbox.font=UGD_FONT6x8;
  winEPropListbox.scrollDnEvent=200;
  winEPropListbox.scrollUpEvent=201;
  winEPropListbox.selectEvent=202;
  winEPropListbox.scrollDnCallback=NULL;//&boxDnCallback;
  winEPropListbox.scrollUpCallback=NULL;//&boxDnCallback;
  winEPropListbox.selectCallback=&winEPropSelectCallback;//&boxSelectCallback; 
  winEPropListbox.fgColor=0xffffff;
  winEPropListbox.bgColor=0x666600;   
  winEPropListbox.fgColorSelected=0xffffff;
  winEPropListbox.bgColorSelected=0xaa;
  
  winEProp.x=30;winEProp.y=40;winEProp.w=100;winEProp.h=40;
  winEProp.bgColor=0x00ffff;
  winEProp.fgColor=0x0000;
  winEProp.objn=0;  winEProp.attr = UGUI_WINATTR_DRAWFRAME;
  
  uguiWinAddObj(&winEProp,&winEPropListbox,&uguiListbox);
  //uguiWinAddObj(&winEProp,&winEPropTitle,&uguiLabel);  
  uguiWinAddObj(&winEProp,&comBtnCancel,&uguiBtn);
  //
  
  //Misc window:------------------------
  winMiscListbox.x=10; winMiscListbox.y=30; winMiscListbox.h=2; winMiscListbox.w=1;
  winMiscListbox.itemw=95;  winMiscListbox.itemh=10;
  winMiscListbox.propw=40;  winMiscListbox.proph=10;
  winMiscListbox.label=NULL;
  winMiscListbox.items=misclist; //ptr to arry of charptr(strings)
  winMiscListbox.props=miscproplist;
  winMiscListbox.itemn=2; //no of items in listbox labels
  winMiscListbox.itemi=0;   
  winMiscListbox.flow=0;
  winMiscListbox.font=UGD_FONT6x8;
  winMiscListbox.scrollDnEvent=200;
  winMiscListbox.scrollUpEvent=201;
  winMiscListbox.selectEvent=202;
  winMiscListbox.scrollDnCallback=NULL;//&boxDnCallback;
  winMiscListbox.scrollUpCallback=NULL;//&boxDnCallback;
  winMiscListbox.selectCallback=&winMiscSelectCallback;//&boxSelectCallback; 
  winMiscListbox.fgColor=0xffffff;
  winMiscListbox.bgColor=0xaa0000;   
  winMiscListbox.fgColorSelected=0xffffff;
  winMiscListbox.bgColorSelected=0xaa;
  
  winMiscTitle.x=12; winMiscTitle.y=12; winMiscTitle.h=10; winMiscTitle.w=30;
  winMiscTitle.label=ini_winMiscTitle;
  winMiscTitle.fgColor=0xffffff;
  winMiscTitle.bgColor=0x0000;
  
  winMisc.x=0;winMisc.y=0;winMisc.w=OLED_RESOLUTION_X-1;winMisc.h=OLED_RESOLUTION_Y-1;
  winMisc.fgColor=0xaa0000;  
  winMisc.bgColor=0x0000;
  winMisc.objn=0; winMisc.attr = UGUI_WINATTR_DRAWFRAME;//
      
  uguiWinAddObj(&winMisc,&winMiscListbox,&uguiListbox);
  uguiWinAddObj(&winMisc,&winMiscTitle,&uguiLabel);
  uguiWinAddObj(&winMisc,&winMainDnBtnLab,&uguiLabel);
  uguiWinAddObj(&winMisc,&winMainUpBtnLab,&uguiLabel);
  uguiWinAddObj(&winMisc,&comBtnCancel,&uguiBtn);
  
  
  //Btn window:------------------------
  winBtnListbox.x=10; winBtnListbox.y=30; winBtnListbox.h=6; winBtnListbox.w=1;
  winBtnListbox.itemw=95;  winBtnListbox.itemh=10;
  winBtnListbox.propw=40;  winBtnListbox.proph=10;
  winBtnListbox.label=NULL;
  winBtnListbox.items=btnlist; //ptr to arry of charptr(strings)
  winBtnListbox.props=btnproplist;
  winBtnListbox.itemn=6; //no of items in listbox labels
  winBtnListbox.itemi=0;   
  winBtnListbox.flow=0;
  winBtnListbox.font=UGD_FONT6x8;
  winBtnListbox.scrollDnEvent=200;
  winBtnListbox.scrollUpEvent=201;
  winBtnListbox.selectEvent=202;
  winBtnListbox.scrollDnCallback=NULL;//&boxDnCallback;
  winBtnListbox.scrollUpCallback=NULL;//&boxDnCallback;
  winBtnListbox.selectCallback=&winBtnSelectCallback;//&boxSelectCallback; 
  winBtnListbox.fgColor=0xffffff;
  winBtnListbox.bgColor=0xaa0000;   
  winBtnListbox.fgColorSelected=0xffffff;
  winBtnListbox.bgColorSelected=0xaa;
  
  winBtnsTitle.x=12; winBtnsTitle.y=12; winBtnsTitle.h=10; winBtnsTitle.w=30;
  winBtnsTitle.label=ini_winBtnRTitle;
  winBtnsTitle.fgColor=0xffffff;
  winBtnsTitle.bgColor=0x0000;
  
  winBtns.x=0;winBtns.y=0;winBtns.w=OLED_RESOLUTION_X-1;winBtns.h=OLED_RESOLUTION_Y-1;
  winBtns.fgColor=0xaa0000;  
  winBtns.bgColor=0x0000;
  winBtns.objn=0; winBtns.attr = UGUI_WINATTR_DRAWFRAME;//
      
  uguiWinAddObj(&winBtns,&winBtnListbox,&uguiListbox);
  uguiWinAddObj(&winBtns,&winBtnsTitle,&uguiLabel);
  uguiWinAddObj(&winBtns,&winMainDnBtnLab,&uguiLabel);
  uguiWinAddObj(&winBtns,&winMainUpBtnLab,&uguiLabel);
  uguiWinAddObj(&winBtns,&comBtnCancel,&uguiBtn);
  //uguiWinAddObj(&winBtns,&winBtnListbox,&uguiListbox);
  
  //Post window:------------------------
  winPostListbox.x=10; winPostListbox.y=30; winPostListbox.h=5; winPostListbox.w=1;
  winPostListbox.itemw=95;  winPostListbox.itemh=10;
  winPostListbox.propw=40;  winPostListbox.proph=10;
  winPostListbox.label=NULL;
  winPostListbox.items=postlist; //ptr to arry of charptr(strings)
  winPostListbox.props=postproplist;
  winPostListbox.itemn=5; //no of items in listbox labels
  winPostListbox.itemi=0;   
  winPostListbox.flow=0;
  winPostListbox.font=UGD_FONT6x8;
  winPostListbox.scrollDnEvent=200;
  winPostListbox.scrollUpEvent=201;
  winPostListbox.selectEvent=202;
  winPostListbox.scrollDnCallback=NULL;//&boxDnCallback;
  winPostListbox.scrollUpCallback=NULL;//&boxDnCallback;
  winPostListbox.selectCallback=&winPostSelectCallback;//&boxSelectCallback; 
  winPostListbox.fgColor=0xffffff;
  winPostListbox.bgColor=0xaa0000;   
  winPostListbox.fgColorSelected=0xffffff;
  winPostListbox.bgColorSelected=0xaa;
  
  winPostTitle.x=12; winPostTitle.y=12; winPostTitle.h=10; winPostTitle.w=30;
  winPostTitle.label=ini_winPostTitle;
  winPostTitle.fgColor=0xffffff;
  winPostTitle.bgColor=0x0000; 
  
  winPost.x=0;winPost.y=0;winPost.w=OLED_RESOLUTION_X-1;winPost.h=OLED_RESOLUTION_Y-1;
  winPost.bgColor=0x0000;
  winPost.fgColor=0xaa0000;
  winPost.objn=0; winPost.attr = UGUI_WINATTR_DRAWFRAME;//
    
  uguiWinAddObj(&winPost,&winPostListbox,&uguiListbox);
  uguiWinAddObj(&winPost,&winPostTitle,&uguiLabel);
  uguiWinAddObj(&winPost,&winMainDnBtnLab,&uguiLabel);
  uguiWinAddObj(&winPost,&winMainUpBtnLab,&uguiLabel);
  uguiWinAddObj(&winPost,&comBtnCancel,&uguiBtn);
  
  
  //HW STATS:
  winStatTitle.x=12; winStatTitle.y=12; winStatTitle.h=10; winStatTitle.w=30;
  winStatTitle.label=ini_winStatTitle;
  winStatTitle.fgColor=0xffffff;
  winStatTitle.bgColor=0x000;
  
  winHWstatWrite.x=5;
  winHWstatWrite.y=23;
  
  winStat.x=0;winStat.y=0;winStat.w=OLED_RESOLUTION_X-1;winStat.h=OLED_RESOLUTION_Y-1;
  winStat.bgColor=0x0; winStat.fgColor=0xaa0000;
  winStat.objn=0; winStat.attr = UGUI_WINATTR_DRAWFRAME;//
  uguiWinAddObj(&winStat,&winStatTitle,&uguiLabel);
  uguiWinAddObj(&winStat,&winHWstatWrite,&uguiPrintHWstat);
  uguiWinAddObj(&winStat,&comBtnCancel,&uguiBtn);
  
  //---- Qry window:
  //property editor
  winQryListbox.x=20;winQryListbox.y=48;winQryListbox.w=2;winQryListbox.h=1;
  winQryListbox.itemw=55;  winQryListbox.itemh=10;
  winQryListbox.label=NULL;
  winQryListbox.items=qrylist; //ptr to arry of charptr(strings)
  winQryListbox.props=NULL;
  winQryListbox.itemn=2; //no of items in listbox labels
  winQryListbox.itemi=0;   
  winQryListbox.flow=1;
  winQryListbox.font=UGD_FONT8x8;
  winQryListbox.scrollDnEvent=200;
  winQryListbox.scrollUpEvent=201;
  winQryListbox.selectEvent=202;
  winQryListbox.scrollDnCallback=NULL;//&boxDnCallback;
  winQryListbox.scrollUpCallback=NULL;//&boxDnCallback;
  winQryListbox.selectCallback=&winQrySelectCallback;//&boxSelectCallback; 
  winQryListbox.fgColor=0xffffff;
  winQryListbox.bgColor=0x666600;   
  winQryListbox.fgColorSelected=0xffffff;
  winQryListbox.bgColorSelected=0xaa;
  
  winQryTitle.x=8; winQryTitle.y=35; winQryTitle.h=10; winQryTitle.w=100;
  winQryTitle.label=ini_winQrySaveExit;winQryTitle.font=UGD_FONT6x8;
  winQryTitle.fgColor=0xff;
  winQryTitle.bgColor=0x00ffff;
  
  winQry.x=5;winQry.y=30;winQry.w=150;winQry.h=40;
  winQry.bgColor=0x00ffff;
  winQry.fgColor=0x0000;
  winQry.objn=0;  winQry.attr = UGUI_WINATTR_DRAWFRAME;
  
  uguiWinAddObj(&winQry,&winQryListbox,&uguiListbox);
  uguiWinAddObj(&winQry,&winQryTitle,&uguiLabel);  
  uguiWinAddObj(&winQry,&comBtnCancel,&uguiBtn);
  
  
  
  uguiContextAddWin(&winMain);//0
  uguiContextAddWin(&winImage);//1
  uguiContextAddWin(&winBtns);//2
  uguiContextAddWin(&winPost);  //3
  uguiContextAddWin(&winEProp);//4
  uguiContextAddWin(&winStat);//5
  uguiContextAddWin(&winQry);//6
  uguiContextAddWin(&winMisc); //7
  
  //TRACE_ALL("winPostListbox.x=%d",winPostListbox.x);
  searchImages();
  
}

void searchImages(void)
{
  
  char * filename="*.bin";
  FRESULT r;
  DIR dir;
  FILINFO fno;
  char *fn,*chri;   
  int l; 
  
  for (r=0;r<16;r++) filelist[r]=&sfilelist[r];
  
  fontSetCharPos(0,0);
  winImageListbox.itemn=0;
  winImageListbox.itemi=0;
  
  if ((r = f_mount (0, &fatfs)) == FR_OK) 
  {  
    r = f_opendir(&dir, "\\");
    if (r == FR_OK) 
    {    
      for (;;) 
      {
              r = f_readdir(&dir, &fno);
              if (r != FR_OK || fno.fname[0] == 0) break;
              if (fno.fname[0] == '.') continue;
  #if _USE_LFN
              fn = *fno.lfname ? fno.lfname : fno.fname;
  #else
              fn = fno.fname;
  #endif
              if (fno.fattrib & AM_DIR) {
                  //dir
              } else {
              //if .BIN add to listing.
                 
                 chri=strstr(fn,".BIN");//strpos(fn,".bin");
                 if ((chri)&&(strlen(chri)==4))
                 {
                   strncpy(sfilelist[winImageListbox.itemn],fn,31);
                   winImageListbox.itemn++;
                   TRACE_SCR("%s\n\r",fn);
                 }                              
              }
      }

    
    } else {TRACE_SCR("f_opendir err:%d\n\r",r);}

     /*
    r=find_first(bootrecord, &ffdat);
    //TRACE_SCR("%d :%s\n\r",r,ffdat.ff_name);
    winImageListbox.itemn=0;
    winImageListbox.itemi=0;
  
    if (r==0)
    {
      strncpy(sfilelist[0],ffdat.ff_name,31);
      sfilelist[0][31]=0;
      TRACE_SCR("%d :%s\n\r",r,sfilelist[winImageListbox.itemn]);
      winImageListbox.itemn=1;
      while (!(r=find_next(&ffdat)))
      {
        strncpy(sfilelist[winImageListbox.itemn],ffdat.ff_name,31);
        sfilelist[winImageListbox.itemn][31]=0;      
        TRACE_SCR("%d :%s\n\r",r,sfilelist[winImageListbox.itemn]);
        winImageListbox.itemn++;
      }
      */    
      
  } else TRACE_SCR("f_mount err:%d\n\r",r);  
    
  readBootImage();  
  
          
  
  /*
  //read image name
  fboot = fat_open("boot",_O_WRONLY);
  if (fboot!=-1)
  {
    TRACE_SCR("Boot written\n\r");
    strncpy(bootname,"main.bin\r\n",12);
    fat_write(fboot, bootname, 12);
  }
  /*
  fboot = fat_open("boot",_O_TEXT|_O_RDONLY);
  if (fboot!=-1)
  {               
    //read SD image
    readbytes=fat_read(fboot, rbuf, 32);
    rbuf[readbytes]=0;
    strncpy(bootname,rbuf,10);
           
  } else {
    // no support yet... see fat.c
    fboot = fat_open("boot",_O_WRONLY);
    strncpy(bootname,"main.bin\r\n",12);
    fat_write(fboot, bootname, 12);
          
  }
  
  fat_close(fboot);
  */  
  /*
  //f_mount(0,&fatfs);
      if ((r=f_open(&fsfile,"boot",FA_WRITE))== FR_OK) 
        {
          if (r=f_write(&fsfile,buff,32,&bread)== FR_OK)
          {
            f_close(&fsfile);
          }  else TRACE_SCR("f_write err:%d",r);
        }   else TRACE_SCR("f_open err:%d",r);
  */        
}

void readBootImage(void)
{
  if ((r=f_open(&bootrecord, "boot", FA_READ|FA_WRITE))== FR_OK)
  {
    if ((r=f_read(&bootrecord,buff,32,&bread))== FR_OK)
    {
      buff[31]=0;
      strncpy(bootname,buff,31);
      bootname[bread-1]=0;
      TRACE_SCR("boot:%s\n\r",bootname);
          
    } else {TRACE_SCR("f_read boot e:%d\n\r",r);}
    f_close(&bootrecord);  
  } else {TRACE_SCR("f_open boot e:%d\n\r",r);}
}

void blConfig(void)
{
  volatile AT91PS_PIO  pPIOB = AT91C_BASE_PIOB;
  fontSetCharPos(0,20);
  readSetupConf();
  
    
    blConfGuiInit();
    
    
    uguiContextWrapper();
    uguiContextSwitch(0);
    delayms(1500);
    while(1)
    {
      if (scrrot)
      {
        if (!((pPIOB->PIO_PDSR)&(BUT2_MASK)))
        {
          uguiWriteEvt(200);
          delayms(300);
        }
        if (!((pPIOB->PIO_PDSR)&(BUT4_MASK)))
        {
          uguiWriteEvt(102);
          delayms(300);
        }
        if (!((pPIOB->PIO_PDSR)&(BUT0_MASK)))
        {
          uguiWriteEvt(201);
          delayms(300);
        }
      } else {
        if (!((pPIOB->PIO_PDSR)&(BUT0_MASK)))
        {
          uguiWriteEvt(200);
          delayms(300);
        }
        if (!((pPIOB->PIO_PDSR)&(BUT3_MASK)))
        {
          uguiWriteEvt(102);
          delayms(300);
        }
        if (!((pPIOB->PIO_PDSR)&(BUT2_MASK)))
        {
          uguiWriteEvt(201);
          delayms(300);
        }
      } 
      
      if (!((pPIOB->PIO_PDSR)&(BUT1_MASK)))
      {
        uguiWriteEvt(202);
        delayms(300);
      }
      uguiContextWrapper();
      delayms(50);
      TRACE_ALL("w");
    };
    
}
    