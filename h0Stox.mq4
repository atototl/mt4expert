//+------------------------------------------------------------------+
//|                                                       h0Test.mq4 |
//|                                                             Heb0 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Heb0"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <stderror.mqh> 
#include <stdlib.mqh> 

#define MAGICMA  0x20160404
#define M5  0
#define M15 1
#define M30 2
#define H1  3

double ma, mu, md, deltama;
double sl=0.0, tp=0.0;
double sto, deltasto, stosig;
double profit = 0.0;
double lot = 0.5;
int level = 0;
int ocount = 0;
double lvl = 0;
double stx[4];

void DrawBuy(double pos) {
  ocount++;
  string oname="BUY-"+IntegerToString(ocount,0,' ');
  ObjectCreate(ChartID(),oname,OBJ_ARROW_UP,0,TimeCurrent(),pos);
}

void DrawSell(double pos) {
  ocount++;
  string oname="SELL-"+IntegerToString(ocount,0,' ');
  ObjectCreate(ChartID(),oname,OBJ_ARROW_DOWN,0,TimeCurrent(),pos);
}

void CheckForMoment() {
  double s1=iStochastic(Symbol(),PERIOD_M15,5,3,3,MODE_SMA,0,MODE_MAIN,3);
  double s2=iStochastic(Symbol(),PERIOD_M15,5,3,3,MODE_SMA,0,MODE_MAIN,1);
  if((s1>80)&&(s2<80)){
    DrawSell(High[1]+0.0010);
  }
  if((s1<20)&&(s2>20)){
    DrawBuy(Low[1]-0.0010);
  }
}

double CalcHSto() {
  double tmp=iStochastic(Symbol(),PERIOD_M15,5,3,3,MODE_SMA,0,MODE_MAIN,1);
  if((tmp-iStochastic(Symbol(),PERIOD_M15,5,3,3,MODE_SMA,0,MODE_MAIN,2))<0)
    tmp=0.0-tmp;
  return tmp;
}

double CalcPower() { // если >0 то тренд продолжается, если <0 будет разворот
  /*int i=0, j=0;
  for(i=1; i<5; i++) {
    if(Doji(i,0.00007)) continue;
    break;
  }
  for(j=i+1;j<(i+5);j++) {
    if(Doji(j,0.00007)) continue;
    break;
  }
  double dhi = High[i]-High[j];
  double dlo = Low[i]-Low[j];
  return (dhi-dlo);*/
  double dhi=0.0;
  double dlo=0.0;
  int i;
  for(i=1;i<4;i++) {
    dhi=dhi+(High[i]-High[i+1]);
    dlo=dlo+(Low[i]-Low[i+1]);
  }
  return (dhi-dlo);
}

int CalcDirection() {
  if(iMA(NULL,0,5,0,MODE_SMA,PRICE_OPEN,2)>iMA(NULL,0,5,0,MODE_SMA,PRICE_OPEN,1)) return -1;
  if(iMA(NULL,0,5,0,MODE_SMA,PRICE_OPEN,2)<iMA(NULL,0,5,0,MODE_SMA,PRICE_OPEN,1)) return 1;
  return 0;
}

void CalculateBands() {
   ma=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_MAIN,0);
   mu=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_UPPER,0);
   md=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_LOWER,0);
   deltama=ma-iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_MAIN,1);
}

void CalculateStochastick() {
  sto=iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
  stosig=iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
  deltasto=sto-iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
}

double CalcSt(int frame, int shift) {
  double tmp=iStochastic(Symbol(),frame,5,3,3,MODE_SMA,0,MODE_MAIN,shift);
  if(tmp>80) lvl=1.0;
  if(tmp<20) lvl=-1.0;
  return tmp*lvl;
}

int CalcTrend() {
  //double ma=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_MAIN,0);
  //double mu=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,0);
  //double md=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,0);
  if( (Close[3]>mu) && (Close[2]>mu) && (Close[1]>mu) ) return 1;
  if( (Close[3]<md) && (Close[2]<md) && (Close[1]<md) ) return -1;
  return 0;
}

void CalcStX() {
  stx[M5]  = CalcSt(PERIOD_M5,0);
  stx[M15] = CalcSt(PERIOD_M15,0);
  stx[M30] = CalcSt(PERIOD_M30,0);
  stx[H1]  = CalcSt(PERIOD_H1,0);
}

bool Doji(int shift, double lim) {
  return (MathAbs(Open[1]-Close[shift])<lim);
}

int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
   if(buys>0) return(buys);
   else       return(-sells);
  }

double LotsOptimized() {
  return lot;
  if(profit>0) lot=lot+0.1;
  if(profit<0) lot=lot-0.1;
  if(lot<0.1) lot=0.1;
  if(lot>1.0) lot=1.0;
  return lot;
}

void DoBuy() {
  tp=Ask+0.0050;
//  sl=Ask-0.0020;
  int res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"",MAGICMA,0,Blue);
  if(res==-1) printf("Order ERROR: %s",ErrorDescription(GetLastError()));
}

void DoSell() {
  tp=Bid-0.0050;
//  sl=Bid+0.0020;
  int res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"",MAGICMA,0,Red);
  if(res==-1) printf("Order ERROR: %s",ErrorDescription(GetLastError()));
}

void CheckForOpen() {
  //return;
  double hsto;
  if(Volume[0]>1) return;
  if(profit>100.0) return;
  CalculateBands();
  CalculateStochastick();
  CalcStX();
  if(stx[M5]==0.0) return;
  if(stx[M5]>0) {
    if(MathAbs(stx[M5])<75) {
      if((mu-md)<0.0009) return;
      if(CalcTrend()==1) { printf("TREND UP"); return; }
      //if((stx[M15]>0) && (stx[H1]>0) && (MathAbs(stx[H1])<80))
      printf("[SELL]           %f %f %f",stx[M5],stx[M15],stx[H1]);
      DoSell();
    }
  }
  if(stx[M5]<0) {
    if(MathAbs(stx[M5])>25) {
      if((mu-md)<0.0009) return;
      if(CalcTrend()==-1) { printf("TREND DOWN"); return; }
      //if((stx[M15]<0) && (stx[H1]<0) && (MathAbs(H1)>20))
      printf("[BUY]           %f %f %f",stx[M5],stx[M15],stx[H1]);
      DoBuy();
    }
  }
  /*switch(level) {
    case 0:
      if(sto<20) level=-1;
      if(sto>80) level=1;
      break;
    case -1:
      if(sto>20) {
        if((mu-md)<0.0009) return;
        if(High[1]>ma) return;
        DoBuy();
      }
      break;
    case 1:
      if(sto<80) {
        if((mu-md)<0.0009) return;
        if(Low[1]<ma) return;
        DoSell();
      }
      break;
  }*/
}

void CheckForClose() {
  if(Volume[0]>1) return;
  double hsto;
  CalculateBands();
  CalculateStochastick();
  CalcStX();
  //ma=iBands(NULL,0,15,2.0,0,PRICE_CLOSE,MODE_MAIN,0);
  //mu=iBands(NULL,0,15,2.0,0,PRICE_CLOSE,MODE_UPPER,0);
  //md=iBands(NULL,0,15,2.0,0,PRICE_CLOSE,MODE_LOWER,0);  
  for(int i=0;i<OrdersTotal();i++) {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
    if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
    if(OrderType()==OP_BUY) {
      /*if(level==-1) {
        if(sto>80) level=1;
      } else {
        if(sto<90) {
          if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))  Print("OrderClose error ",GetLastError());
          //level=0;
          //DoSell();
        }
      }*/
      if(Open[0]>mu) {
        printf("[CLOSE] %f           %f %f %f",OrderProfit(),stx[M5],stx[M15],stx[H1]);
        if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))  Print("OrderClose error ",GetLastError());
        profit=profit+OrderProfit();
      }
    } //-- OP_BUY
    if(OrderType()==OP_SELL) {
      /*if(level==1) {
        if(sto<20) level=-1;
      } else {
        if(sto>10) {
          if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))  Print("OrderClose error ",GetLastError());
          //level=0;
          //DoBuy();
        }
      }*/
      if(Low[1]<md) {
          printf("[CLOSE] %f           %f %f %f",OrderProfit(),stx[M5],stx[M15],stx[H1]);
          if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))  Print("OrderClose error ",GetLastError());
          profit=profit+OrderProfit();
      }
      //if((stx[M15]>0) && (MathAbs(stx[M15])<25)){
      //    printf("[CLOSE1] %f           %f %f %f",OrderProfit(),stx[M5],stx[M15],stx[H1]);
      //    if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))  Print("OrderClose error ",GetLastError());
      //    profit=profit+OrderProfit();
      //}
    } //-- OP_SELL
  }
}

void OnTick()
  {
   if(Bars<100 || IsTradeAllowed()==false)
      return;

   //CheckForMoment();
   double ac = iAC(NULL,0,1);
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
   //CalculateStochastick();
   //Comment("Volume: ",Volume[0]," Trend: ",CalcDirection()," Power: ",NormalizeDouble(CalcPower(),4)*100);
  }

int OnInit()
  {
   printf("INIT: AccountFreeMargin = %f",AccountFreeMargin());
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
  }