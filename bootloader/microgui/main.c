/* ========================================================================== */
/*                                                                            */
/*   Filename.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

//microgui tester

#include <stdio.h>
#include <stdint.h>
//#include "ints.h"
 
#include "ugscrdrv.h"
#include "microgui.h"
tugui_Btn btn1;
tugui_Btn btn2;
tugui_Btn btn21;
tugui_Btn btn22;
char lab1[] = "BTN1";
char lab2[] = "BTN2";
char lab21[] = "BTN21";
char lab22[] = "BTN22";
char lab3[] = "LSTBOX";

char *itemsx[]={"item1","item2","item3"};

tugui_ListboxItems items=itemsx;
tugui_Listbox box;

tugui_Win win;
tugui_Win win2;

//obj callbacks:

int btn1cb(void *p)
{
  printf("@btn1 callback ");
  return -123;
}

int btn2cb(void *p)
{
  printf("@btn2 callback ");
  uguiContextSwitch(1);
  return -123;
}

int boxDnCallback(void *p)
{
  int *index = p; 
  printf("@boxDn callback:%d | ",*index);  
  return -123;
}


int main()
{
   
   btn1.x=1;btn1.y=1;btn1.w=30;btn1.h=20;
   btn1.label = lab1;
   btn1.releaseCallback=NULL;
   btn1.pushCallback= &btn1cb;
   btn1.pushEvent=100;
   btn1.releaseEvent=0;
   
   btn2.x=5;btn2.y=22;btn2.w=22;btn2.h=22;
   btn2.label = lab2;
   btn2.releaseCallback=NULL;
   btn2.pushCallback= &btn2cb;
   btn2.pushEvent=102;
   btn2.releaseEvent=0;
   
   btn21.x=2;btn21.y=20;btn21.w=22;btn21.h=22;
   btn21.label = lab21;
   btn21.releaseCallback=NULL;
   btn21.pushCallback= NULL;
   btn21.pushEvent=300;
   btn21.releaseEvent=0; 
   
   btn22.x=2;btn22.y=2;btn22.w=22;btn22.h=22;
   btn22.label = lab22;
   btn22.releaseCallback=NULL;
   btn22.pushCallback= NULL;
   btn22.pushEvent=300;
   btn22.releaseEvent=0;
   
   box.x=0; box.y=40; //x,y pos of topleft corner in pix
   box.w=80; box.h=60; //width, length in pix
   box.itemw=80;
   box.itemh=10; //width, length in pix
   box.label=lab3;
   box.items=items; //ptr to arry of charptr(strings)
   box.itemn=3; //no of items in listbox labels
   box.itemi=0;   
   box.flow=0;
   box.scrollDnEvent=200;
   box.scrollUpEvent=201;
   box.selectEvent=202;
   box.scrollDnCallback= &boxDnCallback;
   box.scrollUpCallback=NULL;
   box.selectCallback=NULL; 
   box.fgColor=0x11;
   box.bgColor=0xbb;   
   box.fgColorSelected=0x22;
   box.bgColorSelected=0xaa;
   
   
   printf("hello.\n");
   
   win.x=0; win.y=0; win.w=100; win.h=150;
   win.objn=3;
   win.objs[0].obj=&btn1;
   win.objs[0].evthandler=&uguiBtn;
   win.objs[1].obj=&btn2;
   win.objs[1].evthandler=&uguiBtn;
   win.objs[2].obj=&box;
   win.objs[2].evthandler=&uguiListbox;
   
   win2.x=1; win2.y=1; win2.w=100; win2.h=140;
   win2.objn=2;
   win2.objs[0].obj=&btn21;
   win2.objs[0].evthandler=&uguiBtn;
   win2.objs[1].obj=&btn22;
   win2.objs[1].evthandler=&uguiBtn;
   
   //
   uguiContextAddWin(win);
   uguiContextAddWin(win2);
   uguiContextSwitch(0);
   
   uguiContextWrapper();
   uguiWriteEvt(200);
   uguiContextWrapper();
   uguiWriteEvt(200);
   uguiWriteEvt(102);
   uguiContextWrapper();
   
   
      uguiContextWrapper();
      uguiContextWrapper();
         uguiContextWrapper();
   //uguiWin(&win,102);
   //uguiWin(&win,100);
   //win.objs[0].evthandler(win.objs[0].obj,100);
   //win.objs[1].evthandler(win.objs[1].obj,102);
   
   //printf("%s %s %s",items[0],items[1],items[2]);
}
