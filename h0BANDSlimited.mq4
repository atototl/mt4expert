//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
//
// 02.04.2016 - открывать второй ордер после закрытия, если
//    тренд продолжается
// 03.04.2016 - закрывать по Stochastic
// 03.04.2016 - убрал Stochastic, закрытие по Bands с запоминанием
// 03.04.2016 - добавляю локирующий отложенный ордер
//
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Average sample expert advisor"

#include <stderror.mqh> 
#include <stdlib.mqh> 

//#define MAGICMA  20131111
#define MAGICMA  0x20131100
//--- Inputs
input double Lots          =0.1;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
//input int    MovingPeriod  =12;
//input int    MovingShift   =6;
input int StopLoss = 30;
input int TakeProfit = 10;

int ocount = 0;
int bclose = 0;
double sl = 0.0;
double tp = 0.0;
double lastprofit = 0.0;
int lasttype = -1;
bool force = false;
int forcecount = 0;
double prevsto = 0.0;
bool stoflag = false;
bool trigg = false;
double prevmu, prevmd, deltamu, deltamd;
int mainorder = -1;
int lockorder = -1;
int proboy = 0;

void DoBuy () {
  //double sto=iStochastic(Symbol(),0,5,5,5,MODE_SMA,0,MODE_MAIN,0);
  //if(sto>80) return;
  if(StopLoss!=0)
    sl = Ask-NormalizeDouble(StopLoss/10000.0,4);
  if(TakeProfit!=0)
    tp = Ask+NormalizeDouble(StopLoss/10000.0,4);
  int res;
  res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"",MAGICMA,0,Blue);
  mainorder=res;
  if(res==-1) {
    printf("Order ERROR: %s",ErrorDescription(GetLastError()));
    return;
  }
  /*lockorder=OrderSend(Symbol(),OP_SELLSTOP,LotsOptimized(),Ask-0.0030,3,0,0,"",MAGICMA,0,Blue);
  if(lockorder==-1) {
    printf("Lock Order ERROR: %s",ErrorDescription(GetLastError()));
  }*/
}

void DoSell() {
  //double sto=iStochastic(Symbol(),0,5,5,5,MODE_SMA,0,MODE_MAIN,0);
  //if(sto<20) return;
  if(StopLoss!=0)
    sl = Bid+NormalizeDouble(StopLoss/10000.0,4);
  if(TakeProfit!=0)
    tp = Bid-NormalizeDouble(StopLoss/10000.0,4);
  int res;
  res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"",MAGICMA,0,Red);
  mainorder=res;
  if(res==-1) {
    printf("Order ERROR: %s",ErrorDescription(GetLastError()));
    return;
  }
  /*lockorder=OrderSend(Symbol(),OP_BUYSTOP,LotsOptimized(),Bid+0.0030,3,0,0,"",MAGICMA,0,Blue);
  if(lockorder==-1) {
    printf("Lock Order ERROR: %s",ErrorDescription(GetLastError()));
  }*/
}

void DoClose() {
  if(OrderType()==OP_BUY) {
    if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White)) Print("OrderClose error ",GetLastError());
  }
  if(OrderType()==OP_SELL) {
    if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White)) Print("OrderClose error ",GetLastError());
  }
}

int CalcTrend() {
  double mu=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,1);
  double md=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,1);
  //printf("[TREND] %f %f",mu,md);
  if( /*(Close[3]>mu) &&*/ (Close[2]>mu) && (Close[1]>mu) ) { printf("[TREND] UP"); return 1; }
  if( /*(Close[3]<md) &&*/ (Close[2]<md) && (Close[1]<md) ) { printf("[TREND] DOWN"); return -1; }
  return 0;
}

bool Doji(int shift, double lim) {
  return (MathAbs(Open[1]-Close[shift])<lim);
}

void Dodze() {
  if(MathAbs(Open[1]-Close[1])>0.00004) return;
  //ocount++;
  //string oname="Dodze-"+IntegerToString(ocount,0,' ');
  //ObjectCreate(ChartID(),oname,OBJ_ARROW_CHECK,0,TimeCurrent(),Close[1]);
  CheckForClose();
}

void DrawCheck() {
  ocount++;
  string oname="Check-"+IntegerToString(ocount,0,' ');
  ObjectCreate(ChartID(),oname,OBJ_ARROW_CHECK,0,iTime(NULL,0,0),High[1]);
}

void DrawStop() {
  ocount++;
  string oname="Stop-"+IntegerToString(ocount,0,' ');
  ObjectCreate(ChartID(),oname,OBJ_ARROW_STOP,0,iTime(NULL,0,0),High[1]+0.00005);
}

double getSto() {
  double sto = iStochastic(NULL,PERIOD_H1,5,3,3,MODE_SMA,0,0,0);
  if(prevsto>sto) {
    prevsto = sto;
    sto = 0.0 - sto;
  } else {
    prevsto = sto;
  }
  return sto;
}

double getBandSpeed(int mode) {
   double ret = 0.0;
   double mu=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,0);
   double md=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,0);
   if(mode==MODE_UPPER) ret=prevmu-mu;
   if(mode==MODE_LOWER) ret=prevmd-md;
   prevmu=mu; prevmd=md;
   return ret;
}

void CalcBandSpeed() {
   double mu=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,1);
   double md=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,1);
   deltamu=mu-prevmu;
   deltamd=md-prevmd;
   prevmu=mu;
   prevmd=md;
}

//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol)
  {
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
//-!      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
      if(OrderSymbol()==Symbol())
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   //if(buys>0) return(buys);
   //else       return(-sells);
   return(buys+sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   /*double lot=0.1;
   if(AccountFreeMargin()>1500) { lot=0.2; }
   if(AccountFreeMargin()>2000) { lot=0.3; }
   if(AccountFreeMargin()>3000) { lot=0.5; }
   if(AccountFreeMargin()>4000) { lot=1.0; }
   return lot;*/
   double lot=Lots;
   return lot;
   int    orders=HistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break
//--- select lot size
   lot=NormalizeDouble(AccountFreeMargin()*MaximumRisk/1000.0,1);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/DecreaseFactor,1);
     }
//--- return lot size
   if(lot<0.1) lot=0.1;
   return(lot);
  }
  
void OpenForce() {
  force = false;
  double ma,upper,lower;
  if(Volume[0]>1) return;
  if(lastprofit<0.0) return;
  ma=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_MAIN,0);
  upper=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,0);
  lower=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,0);
  if(lasttype==OP_BUY) {
    if(Open[0]>upper) {
    //if(Doji(1,0.00007)) {
    //if(Open[0]>Low[1]) {
      //printf("                FORCE BUY");
      DrawCheck();
      forcecount++;
      DoBuy();
    }
    return;
  }
  if(lasttype==OP_SELL) {
    if(Open[0]<lower) {
    //if(Doji(1,0.00007)) {
    //if(Open[0]<High[1]) {
//      printf("                FORCE SELL");
      DrawCheck();
      forcecount++;
      DoSell();
    }
    return;
  }
}
void TryOpenForce() {
  force = true;
}

double PriceToPips(double price) {
  double lots = OrderLots();
  return price/lots;
}

void CheckForLock() {
  if(mainorder==-1) return;
  if(OrderSelect(mainorder,SELECT_BY_TICKET,MODE_TRADES)==false) return;
  /*double profit=PriceToPips(OrderProfit());
  if(profit<-300) {
      printf("                LOCK OREDER");
      DrawCheck();
      if(OrderType()==OP_BUY) {
        DoSell();
      }
      if(OrderType()==OP_SELL) {
        DoBuy();
      } 
  }*/
  double ma=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_MAIN,0);
  double mu=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,0);
  double md=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,0);
      if(OrderType()==OP_BUY) {
        //if(Open[1]>ma && Close[1]<ma) {
        if(Close[1]<md) {
          DrawCheck();
          DoSell();
        }
      }
      if(OrderType()==OP_SELL) {
        //if(Open[1]<ma && Close[1]>ma) {
        if(Close[1]>mu) {
          DrawCheck();
          DoBuy();
        }
      } 
}
  
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double ma,mu,md;
   //int    res;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   //ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   ma=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_MAIN,0);
   mu=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,0);
   md=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,0);
   double sto = iStochastic(NULL,0/*PERIOD_M30*/,5,3,3,MODE_SMA,0,0,0);
   if(High[1]>mu) proboy=1;
   if(Low[1]<md) proboy=-1;
   
    if(CalcTrend()>0) { DrawCheck(); DoBuy(); }
    if(CalcTrend()<0) { DrawCheck(); DoSell(); }
   
   if((mu-md)<0.0010) return;
   //if(High[1]>upper) return;
   //if(Low[1]<lower) return;
//?   if((upper-lower)<0.0010) return;
//--- sell conditions
   if(Open[1]>ma && Close[1]<ma)
     {
      //if(iSAR(NULL,0,0.02,0.2,1)<Open[0]) return;
      if(proboy==-1) return;
      if(sto<30) return;
      DoSell();
      return;
     }
//--- buy conditions
   if(Open[1]<ma && Close[1]>ma)
     {
      //if(iSAR(NULL,0,0.02,0.2,1)>Open[0]) return;
      if(proboy==1) return;
      if(sto>70) return;
      DoBuy();
      return;
     }
//---

  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   //ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   double ma=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_MAIN,0);
   double mu=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,0);
   double md=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,0);
   double sto = iStochastic(NULL,0/*PERIOD_M30*/,5,3,3,MODE_SMA,0,0,0);
   if(High[1]>mu) proboy=1;
   if(Low[1]<md) proboy=-1;
//---
   for(int i=0;i<OrdersTotal();i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
//-!      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      
//      Comment("Profit: ",OrderProfit());
      
      //--- check order type 
      if(OrderType()==OP_BUY) {
        //if(Low[1]<md) proboy++;
 //       if(iSAR(NULL,0,0.02,0.2,0)>High[1]) proboy=1;
        if(trigg) {
          //if(MathAbs(deltamu)<0.00001) DrawStop();
          //if(MathAbs(deltamd)<0.00001) DrawStop();
          if(Close[1]<mu) {
            //if(sto>82.0) break;
            //if(getBandSpeed(MODE_UPPER)<0) break;
            if(Doji(1,0.00010)) break;
            trigg=false;
            if(OrderTicket()==mainorder) mainorder=-1;
            DoClose();
            proboy=0;
            lastprofit=OrderProfit();
            lasttype=OrderType();
            break;
          }
        }
        if(Close[1]>mu) { trigg=true; break; }
        if(proboy>0) {
          if(High[1]>mu) { DoClose(); trigg=false; }
        }
        
        //if((Open[0]>mu) /*&& (Close[1]>Open[0])*/) {
        //  if(OrderTicket()==mainorder) mainorder=-1;
        //  OrderClose(OrderTicket(),OrderLots(),Bid,3,White);
        //  lastprofit=OrderProfit();
        //  lasttype=OrderType();
        //}
//         break;
      } //OP_BUY
      if(OrderType()==OP_SELL) {
        //if(High[1]>mu) proboy++;
//        if(iSAR(NULL,0,0.02,0.2,0)<Low[1]) proboy=1;
        if(trigg) {
          //if(MathAbs(deltamu)<0.00001) DrawStop();
          //if(MathAbs(deltamd)<0.00001) DrawStop();
          if(Close[1]>md) {
            //if(sto<18.0) break;
            //if(getBandSpeed(MODE_LOWER)>0) break;
            if(Doji(1,0.00010)) break;
            trigg=false;
            if(OrderTicket()==mainorder) mainorder=-1;
            DoClose();
            proboy=0;
            lastprofit=OrderProfit();
            lasttype=OrderType();
            break;
          }
        }
        if(Close[1]<md) { trigg=true; break; }
        if(proboy<0) {
          if(Low[1]<md) { DoClose(); trigg=false; }
        }
        
       //if((Open[0]<md) /*&& (Close[1]<Open[0])*/) {
       //  if(OrderTicket()==mainorder) mainorder=-1;
       //  OrderClose(OrderTicket(),OrderLots(),Ask,3,White);
       //  lastprofit=OrderProfit();
       //  lasttype=OrderType();
       // }
//         break;
      } //OP_SELL
     } //for
//---
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
   //printf("VOLUME = %d",Volume[0]);
   Comment("ForceCount: ",forcecount);
   CalcBandSpeed();

//--- calculate open orders by current symbol
   
   if(CalculateCurrentOrders(Symbol())==0) {
    CheckForOpen();
    if(force)
      OpenForce();
   } else {
     //if( (deltamu<0.0) && (MathAbs(deltamu)<0.00001) ) DrawStop();
     //if( (deltamd>0.0) && (MathAbs(deltamd)<0.00001) ) DrawStop();
     CheckForClose();
     //CheckForLock();
     //Dodze();
//!     TryOpenForce();
   }
   //Dodze();
   
   /*
   switch( CalculateCurrentOrders(Symbol()) ){
     case 0:
       CheckForOpen();
       break;
     case 1:
       CheckForClose();
       //CheckForLock();
       break;
     case 2:
       CheckForClose();
       break;
   }
   */
//---
  }
//+------------------------------------------------------------------+

void OnInit() {
  prevsto = iStochastic(NULL,PERIOD_H1,5,3,3,MODE_SMA,0,0,0);
  prevmu=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_UPPER,0);
  prevmd=iBands(NULL,0,15,2.0,1,PRICE_CLOSE,MODE_LOWER,0);
  printf("INIT: AccountFreeMargin = %f",AccountFreeMargin());
}