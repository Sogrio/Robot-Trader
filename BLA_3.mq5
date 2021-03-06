#include <Trade/Trade.mqh>
#include <Expert/ExpertMoney.mqh>

CTrade trade;
CExpertMoney risk_management;
//Variables de bases
//---
double SL, TP;
double SLSize;
double vol;
bool canLong;
bool canShort;
//---

//Inputs (à configurer)
//---
input int ema9Period = 9;
input int ema18Period = 18;
input int ARTRPeriod = 5;
input double risk = 3.0;// en %
input double coeffAtrSL = 1.5;
input double ATRTrigger = 0.00500;
//---

//Fonctions 
//---
double CalcPositionSize(double r, double S){ // r = risk, A = Ask, S = SL'

   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * r/100;
   double riskPerPip = riskAmount / S;
   double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / _Point;
   
   return (NormalizeDouble(riskPerPip / pipValue, 1));
}
//---

void OnTick()
{
//---
   double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double ema9Buffer[];
   double ema18Buffer[];
   double ATRBuffer[];
   
   static int ema9Handle = iMA(_Symbol,_Period, ema9Period, 0, MODE_EMA, PRICE_CLOSE);
   static int ema18Handle = iMA(_Symbol, _Period, ema18Period, 0, MODE_EMA, PRICE_CLOSE);
   static int ATRHandle = iATR(_Symbol, _Period, ARTRPeriod);
   
   
   ArraySetAsSeries(ema9Buffer, true);
   ArraySetAsSeries(ema18Buffer, true);
   ArraySetAsSeries(ATRBuffer, true);
   
   CopyBuffer(ema9Handle, 0, 0, 100, ema9Buffer); // IMPORTANT : voir si on ne peut pas mettre CopyClose
   CopyBuffer(ema18Handle, 0, 0, 100, ema18Buffer);
   CopyBuffer(ATRHandle, 0, 0, 1, ATRBuffer);
   
   
   //Condition d'autorisation à l'ouverture d'un trade
   //-----
   if (ema9Buffer[0] > ema18Buffer[0] 
    && ema9Buffer[99] <= ema18Buffer[99] 
    && ATRBuffer[0] > ATRTrigger
    && PositionsTotal() == 0)
   {
      canLong = true;
   }
   else
   {
      canLong = false;
   }
   
   /*if (ema9Buffer[0] < ema18Buffer[0] 
    && ema9Buffer[1] >= ema18Buffer[1] 
    && ATRBuffer[0] > 0.00045 
    && PositionsTotal() == 0)
   {
      canShort = true;
   }
   else
   {
      canShort = false;
   }*/
   //-----
   
   //Circonstances de prise de position
   //-----
   if(canLong 
      && ema9Buffer[0] > ema18Buffer[0] 
      && ema9Buffer[99] <= ema18Buffer[99] 
      && PositionsTotal() == 0)
   {
      SL = NormalizeDouble(Bid - ATRBuffer[0]*coeffAtrSL, _Digits);//Position du SL
      SLSize= ATRBuffer[0]*coeffAtrSL; //--> Taille du SL en pips (Prix actuel - Position du SL)
      vol = CalcPositionSize(risk, SLSize);
      trade.Buy(vol, _Symbol, Ask, SL, TP, "Buy");
   }
   
   /*if(canShort 
      && PositionsTotal() == 0
      && ema9Buffer[0] < ema18Buffer[0] 
      && ema9Buffer[1] >= ema18Buffer[1])
   {
      SL = NormalizeDouble(Bid + ATRBuffer[0]*coeffAtrSL, _Digits);//Position du SL
      trade.Sell(10, _Symbol, Ask, SL, TP, "Sell");
   }*/
   //-----
   
   //Gestion du trade ouvert
   //-----
   if(PositionsTotal() == 1 && ema9Buffer[99] > ema18Buffer[99] && ema9Buffer[0] <= ema18Buffer[0]){//dans le cas où on était dans un LONG
      trade.PositionClose(_Symbol);
      canLong = false;
   }
   
   /*if(PositionsTotal() == 1 && ema9Buffer[1] < ema18Buffer[1] && ema9Buffer[0] >= ema18Buffer[0]){//dans le cas où on était dans un LONG
      trade.PositionClose(_Symbol);
      canShort = false;
   }*/
   //-----
//--- 
}

//Calculer la taille de position pour chaque trade à partir d'une part de capital risqué et d'un SL
/*void computeVol(double risk, double SLSize){//1 : part du capital risqué, 2 : taille du Stop Loss
   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) / 100 * risk;
   double riskPerPip = riskAmount / SLSize;
   double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / _Point;
   
   vol = NormalizeDouble(riskPerPip / pipValue, 1);
}*/

