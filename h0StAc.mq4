//+------------------------------------------------------------------+
//|                                                       h0StAc.mq4 |
//|                                                             Heb0 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

// rev.1
//    EURUSD 5M 2016.03.17 652
//    EURUSD 5M 2016.03.18 252
//
// rev.2
//    какие-то доработки
//
// rev.3
//    таки учимс€ открывать замки
//

#property copyright "Heb0"
#property link      "https://www.mql5.com"
#property version   "1.03"
#property strict

#include <stderror.mqh> 
#include <stdlib.mqh> 

#define MAGICMA  20160406
#define CHMIN 0
#define CHMAX 1
int lvl = 0;
double sl=0.0, tp=0.0;
double chnl[2];
int lockcount = 0;
int headcount = 0;

int CheckForLock() {
  int res = 1;
  double ma=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_MAIN,0);
  for(int i=1; i<5; i++) {
    if(OrderType()==OP_BUY) {
      if(Open[i]>ma) {
        res=0;
        break;
      }
    }
    if(OrderType()==OP_SELL) {
      if(Open[i]<ma) {
        res=0;
        break;
      }
    }
  }
  return res;
}

int TestCandle(int shift) {
  if(Open[shift]>Close[shift]) return -1;
  if(Open[shift]<Close[shift]) return 1;
  return 0;
}

void CalcChnl(int shift) {
  chnl[CHMAX]=0.0; chnl[CHMIN]=999999999.0;
  for(int i=0; i<4; i++) {
    if(TestCandle(shift+i)>0) {
      if(Close[shift+i]>chnl[CHMAX]) chnl[CHMAX]=Close[shift+i]+0.0003;
      if(Open[shift+i]<chnl[CHMIN]) chnl[CHMIN]=Open[shift+i]-0.0003;
    }
    if(TestCandle(shift+i)<0) {
      if(Open[shift+i]>chnl[CHMAX]) chnl[CHMAX]=Open[shift+i];
      if(Close[shift+i]<chnl[CHMIN]) chnl[CHMIN]=Close[shift+i];
    }
  }
}

double CalcACD(int shif) {
  return ( iAC(NULL,0,shif)-iAC(NULL,0,shif+1) );
}

void DoBuy() {
//  tp=Ask+0.0050;
//  sl=Ask-0.0020;
  int res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"",MAGICMA,0,Blue);
  if(res==-1) printf("Order ERROR: %s",ErrorDescription(GetLastError()));
}

void DoSell() {
//  tp=Bid-0.0050;
//  sl=Bid+0.0020;
  int res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"",MAGICMA,0,Red);
  if(res==-1) printf("Order ERROR: %s",ErrorDescription(GetLastError()));
}

void DoClose(int colr) {
  if(OrderType()==OP_BUY) {
    if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,colr)) Print("OrderClose error ",GetLastError());
  }
  if(OrderType()==OP_SELL) {
    if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,colr)) Print("OrderClose error ",GetLastError());
  }
  printf("[CLOSE] #%d        $%f",OrderTicket(),OrderProfit());
  headcount = 0;
}

void CheckForOpen() {
  if(Volume[0]>1) return;
  CalcChnl(2);

  double st = iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
  if(st>80) lvl=1;
  if(st<20) lvl=-1;
  if((chnl[CHMAX]-chnl[CHMIN])<0.0005) return;
  if((Close[1]>chnl[CHMAX]) && (Open[1]<chnl[CHMAX])) {
    if(st>80) return;
    //if( (lvl==-1) ) {
      DoBuy();
    //}
  }
  if( (Close[1]<chnl[CHMIN]) && (Open[1]>chnl[CHMIN]) ) {
    if(st<20) return;
    //if( (lvl==1) ) {
      DoSell();
    //}
  }
/*  
    double mu=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_UPPER,1);
    double md=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_LOWER,1);
    //if((mu-md)<0.0010) return;
  double st = iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
  double st1 = iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
  double st2 = iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,2);
  double sts = iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0);
  if(st>80) { lvl=1; }
  if(st<20) { lvl=-1; }
  double ac = iAC(NULL,0,1);
  if((lvl==1)&&(st<80)) {
//    if(ac>iAC(NULL,0,2)) { DoBuy(); return; }
    if( (Open[0]<chnl[CHMAX]) && (Open[0]>chnl[CHMIN]) ) return;
    //if(Close[1]>chnl[CHMIN]) {
    //  printf("[OVER BUY]");
    //  DoBuy();
    //  return;
    //}
    //if( MathAbs(ac)<0.00005 ) return;
    //if(st<sts) return;
    //printf("[SELL]             lvl=%d st=%f ac: %f %f",lvl,st,ac,iAC(NULL,0,2));
    if( (st1-st2)>0 ) return;
    if((Close[1]>mu) && (Close[2]>mu)) return;
    printf("[SELL]             lvl=%d st1=%f st2=%f chnl: %f",lvl,st1,st2,(chnl[CHMAX]-chnl[CHMIN]));
    DoSell(); //DoBuy();
  }
  if((lvl==-1)&&(st>20)) {
    if( (Open[0]<chnl[CHMAX]) && (Open[0]>chnl[CHMIN]) ) return;
    //if(Close[1]<chnl[CHMAX]) {
    //  printf("[OVER SELL]");
    //  DoSell();
    //  return;
    //}
    //if( MathAbs(ac)<0.00005 ) return;
    //if(st>sts) return;
    //printf("[BUY]             lvl=%d st=%f",lvl,st);
    if( (st1-st2)<0 ) return;
    if((Close[1]<md) && (Close[2]<md)) return;
    printf("[BUY]             lvl=%d st1=%f st2=%f chnl: %f",lvl,st1,st2,(chnl[CHMAX]-chnl[CHMIN]));
    DoBuy(); //DoSell();
  }
*/
}

void CheckForClose() {
  if(Volume[0]>1) return;
  for(int i=0;i<OrdersTotal();i++) {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
    if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
    double ma=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_MAIN,0);
    double mu=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_UPPER,0);
    double md=iBands(NULL,0,15,2.0,2,PRICE_MEDIAN,MODE_LOWER,0);
  double st = iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
  if(st>80) { lvl=1; /*printf("[LVL] = 1 st=%f",st);*/ }
  if(st<20) { lvl=-1; /*printf("[LVL] = -1 st=%f",st);*/ }
    double sts = iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_SIGNAL,2);
    double ac = iAC(NULL,0,1);
    if(OrderType()==OP_BUY) {
      if((Close[1]>mu)&&(Close[1]>OrderOpenPrice())) headcount++;
      //if(Open[0]<md) DoClose();
      if((Open[0]>mu)&&(sts>80)) {
        DoClose(clrGreen);
        lvl=0;
        break;
      }
      /*if(sts>80) {
        if(CalcACD(1)>0) return;
        DoClose(clrBlack);
        lvl=0;
      }*/
      if( (Open[1]<md) && (Close[1]>mu) ) {
        DoClose(clrYellow);
        lvl=0;
      }
      /*if( (Open[1]>mu) && (Close[1]>mu) ) {
        DoClose();
        lvl=0;
      }*/
      ////if(OrderProfit()<-150.00) {
      //if(CheckForLock()>0) {
      //  DoClose();
      //  //DoSell();
      //  lockcount++;
      //}
      //if(headcount==2) {
      //  DoClose();
      //}
      break;
    } //--OP_BUY
    if(OrderType()==OP_SELL) {
      if((Close[1]<md)&&(Close[1]<OrderOpenPrice())) headcount++;
      if((Open[0]<md)&&(sts<20)) {
        DoClose(clrGreen);
        lvl=0;
        break;
      }
      /*if(sts<20) {
        if(CalcACD(1)<0) return;
        DoClose(clrBlack);
        lvl=0;
      }*/
      if( (Open[1]>mu) && (Close[0])<md) {
        DoClose(clrYellow);
        lvl=0;
      }
      /*if( (Open[1]<md) && (Close[1]<md) ) {
        DoClose();
        lvl=0;
      }*/
      ////if(OrderProfit()<-150.00) {
      //if(CheckForLock()>0) {
      //  DoClose();
      //  //DoBuy();
      //  lockcount++;
      //}
      //if(headcount==2) {
      //  DoClose();
      //}
      break;
    } //--OP_SELL;
  } //--for
}

int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
  }

double LotsOptimized() {
  return 0.5;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(Bars<100 || IsTradeAllowed()==false)
      return;
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
   Comment("Lock count: ",lockcount);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }