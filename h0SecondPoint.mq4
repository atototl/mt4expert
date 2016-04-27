//+------------------------------------------------------------------+
//|                                                h0SecondPoint.mq4 |
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

double sl=0.0, tp=0.0;
int ticket = -1;
int openbars = 0;

double LotsOptimized() {
  return 0.5;
}

int TestCandle(int shift) {
  if( Open[shift]>Close[shift] ) return -1;
  if( Open[shift]<Close[shift] ) return 1;
  return 0;
}

void SellStop() {
  double mi = MarketInfo(Symbol(),MODE_STOPLEVEL);
  printf("--- Sell stop %f sl/tp %f Bid %f Ask %f",Open[1],mi,Bid,Ask);
  double pr = Open[1]-mi/100000.0;
  //pr=pr-0.0005;
  sl=pr+0.0020;
  tp=pr-0.0010;
  //sl=Open[1]+0.0020;
  //tp=Open[1]-0.0010;
  ticket=OrderSend(Symbol(),OP_SELLSTOP,LotsOptimized(),pr,3,sl,tp,NULL,MAGICMA,0,Red);
  if(ticket==-1) printf("Order ERROR: %s",ErrorDescription(GetLastError()));
}

void BuyStop() {
  double mi = MarketInfo(Symbol(),MODE_STOPLEVEL);
  printf("--- Buy stop %f sl/tp %f",Open[1],mi);
  double pr = Open[1]+mi/100000.0;
  //pr=pr+0.0005;
  sl=pr-0.0020;
  tp=pr+0.0010;
  //sl=Open[1]-0.0020;
  //tp=Open[1]+0.0010;
  ticket=OrderSend(Symbol(),OP_BUYSTOP,LotsOptimized(),pr,3,sl,tp,NULL,MAGICMA,0,Blue);
  if(ticket==-1) printf("Order ERROR: %s",ErrorDescription(GetLastError()));
}

void TryOpen() {
  if(Volume[0]>1) return;
  if(ticket!=-1) return;
  if( (TestCandle(3)==-1) && (TestCandle(2)==-1) && (TestCandle(1)==1) ) {
    SellStop();
  }
  if( (TestCandle(3)==1) && (TestCandle(2)==1) && (TestCandle(1)==-1) ) {
    BuyStop();
  }
  openbars = Bars;
}

void TryClose() {
  if(Volume[0]>1) return;
  if(ticket<0) return;
  if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES)==false) {
    printf("TryClose(): No OrderSelect()");
    return;
  }
  if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) {
    printf("TryClose(): No OrderMagicNumber()");
    return;
  }
  if( OrderType()==OP_BUYSTOP ) {
    if((Bars-openbars)>3) {
      printf("Delete order #%d (type %d)",ticket,OrderType());
      if(!OrderDelete(OrderTicket(),Yellow))  Print("OrderDelete error ",ErrorDescription(GetLastError()));
      ticket=-1;
    }
  }
  if( OrderType()==OP_SELLSTOP ) {
    if((Bars-openbars)>3) {
      printf("Delete order #%d (type %d)",ticket,OrderType());
      if(!OrderDelete(OrderTicket(),Yellow))  Print("OrderDelete error ",ErrorDescription(GetLastError()));
      ticket=-1;
    }
  }
}

void CheckForOpen() {
  if(Volume[0]>1) return;
  if( (TestCandle(3)==-1) && (TestCandle(2)==-1) && (TestCandle(1)==1) ) {
    SellStop();
  }
  if( (TestCandle(3)==1) && (TestCandle(2)==1) && (TestCandle(1)==-11) ) {
    BuyStop();
  }
}

void CheckForClose() {
  if(Volume[0]>1) return;
  /*if(ticket==-2) {
    ticket=-1;
    return;
  }*/
  for(int i=0;i<OrdersTotal();i++) {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
    if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
    
    if((OrderType()==OP_BUYSTOP)||(OrderType()==OP_SELLSTOP)) {
      return;
//    if(OrderCloseTime()==0) {
//      if(TickCount>3) {
//        if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))  Print("OrderClose error ",GetLastError());
//      }
//    }
    
    }
    if((OrderType()==OP_BUY)||(OrderType()==OP_SELL)) {
      return;
    }
  } //--for
  //ticket=-2;
  ticket=-1;
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

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(Bars<100 || IsTradeAllowed()==false)
      return;
   double mi = MarketInfo(Symbol(),MODE_STOPLEVEL);
   Comment("Bars: ",Bars," sl/tp: ",mi);
   //if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
   //else                                    CheckForClose();   
   if(ticket==-1) {
     TryOpen();
   } else {
     TryClose();
     CheckForClose();
   }
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