#include <Trade/Trade.mqh>
//#include <Expert/ExpertMoney.mqh>

CTrade trade;
//CExpertMoney risk_management;
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
double coeffAtrSL = 1.5;
double risk = 2.0;// en %
//---

//Fonctions 
//---
/*void CalcPositionSize(double r, double A, double S){ // r = risk, A = Ask, S = SL

   double capAmount = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) / 100 * r;
   
   vol = riskAmount / (1 - S/A);
   
}*/

/*double CalcPositionSize(double r, double S){ // r = risk, A = Ask, S = SL'

   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * r/100;
   double riskPerPip = riskAmount / S;
   double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / _Point;
   
   return (NormalizeDouble(riskPerPip / pipValue, 1));
}*/

/*
CapAmount : AccountInfoDouble(ACCOUNT_BALANCE) -> Capital Actuel
SL : déterminé par l'ATRBuffer : variable SL
Prix actuel : Ask
r : riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) / 100 * risk;
*/
//---

void OnTick()
{
//---
   int ema9Period = 9;
   int ema18Period = 18;
   int ARTRPeriod = 14;
   //int check_index = 0;
   
   double Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double ema9Buffer[];
   double ema18Buffer[];
   double ATRBuffer[];
   
   static int ema9Handle = iMA(_Symbol, _Period, ema9Period, 0, MODE_EMA, PRICE_CLOSE);
   static int ema18Handle = iMA(_Symbol, _Period, ema18Period, 0, MODE_EMA, PRICE_CLOSE);
   static int ATRHandle = iATR(_Symbol, _Period, ARTRPeriod);
   //static int adxHandle = iADX(_Symbol,_Period, 14);
   
   /*double var = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double vari = _Point;
   Print(var);*/
   
   ArraySetAsSeries(ema9Buffer, true);
   ArraySetAsSeries(ema18Buffer, true);
   ArraySetAsSeries(ATRBuffer, true);
   
   CopyBuffer(ema9Handle, 0, 0, 2, ema9Buffer); // IMPORTANT : voir si on ne peut pas mettre CopyClose
   CopyBuffer(ema18Handle, 0, 0, 2, ema18Buffer);
   CopyBuffer(ATRHandle, 0, 0, 1, ATRBuffer);
   
   if (ema9Buffer[0] > ema18Buffer[0] && ema9Buffer[1] <= ema18Buffer[1] && PositionsTotal() == 0){
      canLong = true;
   }

   if(canLong && ema9Buffer[0] > ema18Buffer[0] && ema9Buffer[1] <= ema18Buffer[1] && PositionsTotal() == 0){
      SL = NormalizeDouble(Bid - ATRBuffer[0]*coeffAtrSL, _Digits);//Position du SL
      //TP = NormalizeDouble(Bid + 2*ATRBuffer[0]*coeffAtrSL, _Digits);//Position du SL
      //SLSize= ATRBuffer[0]*coeffAtrSL; //--> Taille du SL en pips (Prix actuel - Position du SL)
      //vol = CalcPositionSize(risk, SLSize);
      //risk_management.Percent(risk);
      //vol = risk_management.CheckOpenLong(Ask, SL);
      //Print(vol);
      trade.Buy(2, _Symbol, Ask, SL, TP, "Buy");
   }
   
   if(PositionsTotal() == 1 && ema9Buffer[1] > ema18Buffer[1] && ema9Buffer[0] <= ema18Buffer[0]){//dans le cas où on était dans un LONG
      trade.PositionClose(_Symbol);
      canLong = false;
   }
//--- 
}

//Calculer la taille de position pour chaque trade à partir d'une part de capital risqué et d'un SL
/*void computeVol(double risk, double SLSize){//1 : part du capital risqué, 2 : taille du Stop Loss
   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) / 100 * risk;
   double riskPerPip = riskAmount / SLSize;
   double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / _Point;
   
   vol = NormalizeDouble(riskPerPip / pipValue, 1);
}*/

