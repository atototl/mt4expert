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

double ma, mu, md, deltama;
double sl=0.0, tp=0.0;
double sto, deltasto, stosig;
double profit = 0.0;
double lot = 0.5;
//int magic = 0;
bool stolo = false;
bool stohi = false;
int level = 0;
/*void CalcMagic() {
  if(OrderProfit()<0) { magic=0; return; }
  if(OrderType()==OP_BUY) magic++;
  if(OrderType()==OP_SELL) magic--;
  if(magic>2) magic=2;
  if(magic<-2) magic=-2;
}*/

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

void CalculateBands(int shift) {
   ma=iBands(NULL,0,15,2.0,2,PRICE_CLOSE,MODE_MAIN,shift);
   mu=iBands(NULL,0,15,2.0,2,PRICE_CLOSE,MODE_UPPER,shift);
   md=iBands(NULL,0,15,2.0,2,PRICE_CLOSE,MODE_LOWER,shift);
   deltama=ma-iBands(NULL,0,15,2.0,2,PRICE_CLOSE,MODE_MAIN,shift+1);
}

void CalculateStochastick() {
  sto=iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,1);
  stosig=iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_SIGNAL,1);
  deltasto=sto-iStochastic(Symbol(),0,5,3,3,MODE_SMA,0,MODE_MAIN,2);
  if(sto>80) level=1;
  if(sto<20) level=-1;
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
  CalculateBands(2);
  CalculateStochastick();
  if( (High[1]>mu) && (sto>79) ) {
//+1  if( (High[1]>mu) && (sto>79) && (sto<stosig) ) {
    if((mu-md)<0.0009) return;
//+4    if((CalcDirection()==1)&&(CalcPower()>0.0)) {
//      return;
//    }
//+8:
        hsto=CalcHSto();
        if( /*(hsto>0) &&*/ (MathAbs(hsto)>70) ) return;
//-
    DoSell();
  }
  if( (Low[1]<md) && (sto<21) ) {
//+1  if( (Low[1]<md) && (sto<21) && (sto>stosig) ) {
    if((mu-md)<0.0009) return;
//+4    if((CalcDirection()==-1)&&(CalcPower()>0.0)) {
//      return;
//    }
//+8:
        hsto=CalcHSto();
        if( /*(hsto<0) &&*/ (MathAbs(hsto)<30) ) return;
//-
    DoBuy();
  }
}

void CheckForClose() {
  if(Volume[0]>1) return;
  double hsto;
  CalculateBands(0); // !!!!!
  CalculateStochastick();
  for(int i=0;i<OrdersTotal();i++) {
    if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
    if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
    if(OrderType()==OP_BUY) {
//-6      if((High[1]>mu)&&(sto>80)) {
      if(sto>80) stohi=true;
      if((High[2]>mu)&&(High[1]<mu)&&(sto>79)) { //+6
//-6      if(Doji(1,0.00007)) return;
      //if(Close[1]>ma) {
//+5:
//      if((CalcDirection()==1)&&(CalcPower()>0.0)) return;
//-
//+7:
//        hsto=CalcHSto();
//        Comment("HSto: ",hsto);
//        if( (hsto>0) && (MathAbs(hsto)<80) ) return;
//-
        if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))  Print("OrderClose error ",GetLastError());
        profit = OrderProfit();
        stohi=false;
      }
      if(sto>90) {
        CalculateBands(2);
        if(High[1]<md)
          if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))  Print("OrderClose error ",GetLastError());
      }
      CalculateBands(2);
      if(High[1]>mu) {
        if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))  Print("OrderClose error ",GetLastError());
      }
    }
    if(OrderType()==OP_SELL) {
//-6      if((Low[1]<md)&&(sto<20)) {
      if(sto<20) stolo=true;
      if( (Low[2]<md)&&(Low[1]>md)&&(sto<21) ) { //+6
//-6      if(Doji(1,0.00007)) return;
      //if(Close[1]<ma) {
//+5:
//      if((CalcDirection()==-1)&&(CalcPower()>0.0)) return;
//-      
//+7:
//        hsto=CalcHSto();
//        Comment("HSto: ",hsto);
//        if( (hsto<0) && (MathAbs(hsto)>20) ) return;
//-
        if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))  Print("OrderClose error ",GetLastError());
        profit = OrderProfit();
        stolo=false;
      }
      if(sto<10) {
        CalculateBands(2);
        if(Low[1]<md)
          if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))  Print("OrderClose error ",GetLastError());
      }
      if(level==-1) {
        CalculateBands(2);
        if(Low[1]<md)
          if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))  Print("OrderClose error ",GetLastError());
      }
    }
  }
}

void OnTick()
  {
   if(Bars<100 || IsTradeAllowed()==false)
      return;

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