//+------------------------------------------------------------------+
//|                                               Moving Average.mq4 |
//|                   Copyright 2005-2014, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright   "2005-2014, MetaQuotes Software Corp."
#property link        "http://www.mql4.com"
#property description "Moving Average sample expert advisor"

#define MAGICMA  20131111
//--- Inputs
input double Lots          =0.1;
input double MaximumRisk   =0.02;
input double DecreaseFactor=3;
input int    MovingPeriod  =12;
input int    MovingShift   =6;

double prevma = 0.0;
int prevf = 0;

int CalcFlip()
{
  if( iSAR(NULL,0,0.02,0.2,0)>Ask ) {
    return -1;
  }
  if( iSAR(NULL,0,0.02,0.2,0)<Bid ) {
    return 1;
  }
  return 0;
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
   if(buys>0) return(buys);
   else       return(-sells);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lot=Lots;
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
  
void TryOpen() {
  int res;
  double sl, tp;
  int flip=CalcFlip();
  if(flip!=prevf) {
    if(flip==1) { //BUY
      tp=Ask+0.0020;
      sl=Ask-0.0020;
      res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"",MAGICMA,0,Blue);
    }
    if(flip==-1) { //SELL
      tp=Bid-0.0020;
      sl=Bid+0.0020;
      res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"",MAGICMA,0,Red);
    }
  }
  prevf=flip;
}

void TryClose() {
  int flip=CalcFlip();
  if(flip==prevf)
    return;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      if(OrderType()==OP_BUY)
        {
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
         break;
        }
      if(OrderType()==OP_SELL)
        {
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
         break;
        }
     }  
}
  
//+------------------------------------------------------------------+
//| Check for open order conditions                                  |
//+------------------------------------------------------------------+
void CheckForOpen()
  {
   double ma;
   double ma1;
   double ma2;
   int    res;
   double sl;
   double tp;
   bool f1;
   bool f2;
   string op1;
   string op2;
   
//--- go trading only for first tiks of new bar
  if(Volume[0]>1) return;
  //if(Volume[0]<1) return;

  sl=0.0; tp=0.0;

  ma=iSAR(NULL,0,0.02,0.2,0);
  ma1=iSAR(NULL,0,0.02,0.2,1);
  ma2=iSAR(NULL,0,0.02,0.2,2);
  if( (ma2<Low[2]) && (ma1>High[1]) ) {
    tp=Bid-0.0020;
    sl=Bid+0.0010;
    res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"",MAGICMA,0,Red);
    return;
  }
  return;
  //Print(Open[0]," ",Close[0]," ",High[0]," ",Low[0]);
  //Print(Open[0]," ",Low[1]," - ",ma," ",ma1);
  Print((float)Open[0]," ",(float)ma," ",(float)prevma);
  if( (ma>Open[0]) && (prevma<Open[0]) ) {
    Print("SELL");
    tp=Bid-0.0020;
    sl=Bid+0.0020;
    res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"",MAGICMA,0,Red);
  }
  if( (ma<Open[0]) && (prevma>Open[0]) ) {
    Print("BUY");
    tp=Ask+0.0020;
    sl=Ask-0.0020;
    res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"",MAGICMA,0,Blue);
  }
  prevma=ma;
  return;
  
//--- get Moving Average 
   //ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   //ma=iBands(NULL,0,15,2.0,0,PRICE_CLOSE,MODE_MAIN,0);
   //ma=iSAR(NULL,0,0.02,0.2,0);
 

   f1=(ma>High[0]);
   f2=(ma1<Low[1]);
   //if(ma>High[1])
   if( (ma>Open[0]) && (ma1<Close[1]) )
   {
    //sl = Bid + 0.0010;
    tp = Bid - 0.0010;
    res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,sl,tp,"",MAGICMA,0,Red);
    return;
   }
//   if(ma<Low[1])
//   {
//    //sl = Bid - 0.0010;
//    tp = Bid + 0.0010;
//    res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,sl,tp,"",MAGICMA,0,Blue);
//    return;
//   }
//---
  }
//+------------------------------------------------------------------+
//| Check for close order conditions                                 |
//+------------------------------------------------------------------+
void CheckForClose()
  {
   double ma;
//--- go trading only for first tiks of new bar
   if(Volume[0]>1) return;
//--- get Moving Average 
   //ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
   //ma=iBands(NULL,0,15,2.0,0,PRICE_CLOSE,MODE_MAIN,0);
   ma=iSAR(NULL,0,0.02,0.2,0);
   
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) continue;
      //--- check order type 
      if(OrderType()==OP_BUY)
        {
         if(ma>High[0])
         //if(Open[1]>ma && Close[1]<ma)
           {
            
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
      if(OrderType()==OP_SELL)
        {
         if(ma<Low[0])
         //if(Open[1]<ma && Close[1]>ma)
           {
            
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,White))
               Print("OrderClose error ",GetLastError());
           }
         break;
        }
     }
//---
  }
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- check for history and trading
//   if(Bars<100 || IsTradeAllowed()==false)
//      return;
  if(Bars<100)
    return;
  if(prevma==0.0)
    prevma=iSAR(NULL,0,0.02,0.2,0);
  if(prevf==0)
    prevf=CalcFlip();  
//--- calculate open orders by current symbol
   if(CalculateCurrentOrders(Symbol())==0)
   {
     //CheckForOpen();
     TryOpen();
   }
   else
   {
//     CheckForClose();
//     CheckForOpen();
     TryClose();
     TryOpen();
   }
//---
  }
//+------------------------------------------------------------------+
