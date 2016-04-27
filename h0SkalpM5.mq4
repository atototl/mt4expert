//+------------------------------------------------------------------+
//|                                                    h0SkalpM5.mq4 |
//|                                                             Heb0 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Heb0"
#property link      "https://www.mql5.com"
#property version   "1.03"
#property strict

#include <stderror.mqh> 
#include <stdlib.mqh> 

#define MAGICMA  20160425

double tp = 0.0;
double sl = 0.0;
int active = 0;
double ma = 0;
double bma, bu, bd;
double sto;
int trig = 0;
int fcnt = 0;
int skip = 0;

void CalcMA() {
  //ma = iMA(Symbol(),PERIOD_M5,3,1,MODE_SMA,PRICE_TYPICAL,1);
  //dma = ma - iMA(Symbol(),PERIOD_M5,3,1,MODE_SMA,PRICE_TYPICAL,2);
  
  ma = iMA(Symbol(),PERIOD_M15,3,1,MODE_SMA,PRICE_TYPICAL,0);
  //dma = ma - iMA(Symbol(),PERIOD_M15,3,1,MODE_SMA,PRICE_TYPICAL,2);
}

void CalcBands(int shift) {
   bma=iBands(NULL,0,15,2.0,0,PRICE_CLOSE,MODE_MAIN,shift);
   bu=iBands(NULL,0,15,2.0,0,PRICE_CLOSE,MODE_UPPER,shift);
   bd=iBands(NULL,0,15,2.0,0,PRICE_CLOSE,MODE_LOWER,shift);
}

void CalcStochastick() {
  sto=iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,0);
}

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
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized() {
  return 0.5;
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
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   //if(buys>0) return(buys);
   //else       return(-sells);
   return (buys+sells);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoBuy() {
//  tp=Ask+0.0006;
//  sl=Ask-0.0030;
  int res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"",MAGICMA,0,Blue);
  if(res==-1) printf("Order ERROR: %s",ErrorDescription(GetLastError()));
  trig=0;
  fcnt=0;
  skip=1;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoSell() {
//  tp=Bid-0.0006;
//  sl=Bid+0.0030;
  int res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"",MAGICMA,0,Red);
  if(res==-1) printf("Order ERROR: %s",ErrorDescription(GetLastError()));
  trig=0;
  fcnt=0;
  skip=1;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DoClose(int colr) {
  if(OrderType()==OP_BUY) {
    if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,colr)) Print("OrderClose error ",GetLastError());
  }
  if(OrderType()==OP_SELL) {
    if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,colr)) Print("OrderClose error ",GetLastError());
  }
  printf("[CLOSE] #%d        $%f",OrderTicket(),OrderProfit());
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForOpen() {
   MqlDateTime str;
   TimeToStruct(TimeCurrent(),str);
   if( (str.hour<6)||(str.hour>17) ) { active=0; return; }
   if( (str.hour==17)&&(str.min>0) ) { active=0; return; }
   if(Volume[0]>1) return;
   CalcMA();
   CalcBands(1);
   CalcStochastick();
   //if( (Open[1]<ma)&&(Close[1]>ma)&&(Close[1]<bu)&&(sto<80) ) {
   //if( (Open[1]<ma)&&(Close[1]>ma)&&(Close[1]<bu) ) {
   if( (Open[1]<bma)&&(Close[1]>bma)&&(Close[1]<bu) ) {
     if(Open[1]>bma) return;
     printf("[BUY] O %f; C %f; bma %f; bu %f; bd %f",Open[1],Close[1],bma,bu,bd);
     DoBuy();
     return;
   }
   //if( (Open[1]>ma)&&(Close[1]<ma)&&(Close[1]>bd)&&(sto>20) ) {
   //if( (Open[1]>ma)&&(Close[1]<ma)&&(Close[1]>bd) ) {
   if( (Open[1]>bma)&&(Close[1]<bma)&&(Close[1]>bd) ) {
     if(Open[1]<bma) return;
     printf("[SELL] O %f; C %f; bma %f; bu %f; bd %f",Open[1],Close[1],bma,bu,bd);
     DoSell();
     return;
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckForClose() {
  if(Volume[0]>1) return;
  if(skip>0) { skip--; return; }
  MqlDateTime str;
  TimeToStruct(TimeCurrent(),str);
  CalcMA();
  CalcBands(1);
  for(int i=0;i<OrdersTotal();i++) {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
    if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
    if( (str.hour==19)&&(str.min>=0) ) {
        DoClose(clrGold);
        printf("[CLOSE] by end of day");
        break;
    }

    if(OrderType()==OP_BUY) {
      if(Close[1]>bu) {
//      if(Open[0]>bu) {
        DoClose(clrSilver);
        break;
      }
      if( (Open[1]>bma)&&(Close[1]<bma) ) fcnt++;
      if( (fcnt>0)&&(High[1]>bu) ) {
        DoClose(clrBlack);
        break;
      }
      if(fcnt>1) {
        DoClose(clrBlack);
//        DoSell();
        break;
      }
      //if( (Open[1]>ma)&&(Close[1]<ma) ) {
      //  DoClose(clrBlack);
      //  break;
      //}
      //if(Close[1]<bd) {trig=1; break; }
      //if( (trig==1)&&(Close[1]>ma) ) {
      //  DoClose(clrBlack);
      //  break;
      //}
      break;
    } //--OP_BUY


    if(OrderType()==OP_SELL) {
      if(Close[1]<bd) {
//      if(Open[0]<bd) {
        DoClose(clrSilver);
        break;
      }
      if( (Open[1]<bma)&&(Close[1]>bma) ) fcnt++;
      if( (fcnt>0)&&(Low[1]<bd) ) {
        DoClose(clrBlack);
        break;
      }
      if(fcnt>1) {
        DoClose(clrBlack);
//        DoBuy();
      }
      //if( (Open[1]<ma)&&(Close[1]>ma) ) {
      //  DoClose(clrBlack);
      //  break;
      //}
      //if(Close[1]>bu) {trig=1; break; }
      //if( (trig==1)&&(Close[1]<ma) ) {
      //  DoClose(clrBlack);
      //  break;
      //}
      break;
    } //--OP_SELL
    
  } //--for
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
      return;
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   else                                    CheckForClose();
  }
//+------------------------------------------------------------------+
