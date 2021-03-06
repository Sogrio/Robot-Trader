#include <Trade/Trade.mqh>
CTrade trade;

//Variables : Prix
double Ask, Bid;

//Variables : Prise de position
double SL, SLSize;
double TP;
bool canLong, canShort;
double vol;
string lastTradeType;

//Variables : Indicateurs
int rsiHandle, atrHandle;
double rsiBuffer[], atrBuffer[];

//---
//RECTIFIER LE TP
//Inputs (à configurer)
//---
input int atrPeriod = 5;
input int rsiPeriod = 14;
input double risk = 1.0;// en %
input double RRCoeff = 2;
input double SLATR = 0.5;
/*input double TPAtr = 4.5;*/
input int lowRsiTrigger = 25;
input int middleHighRsiTrigger = 55;
input int middleLowRsiTrigger = 45;
input int highRsiTrigger = 75;
input double updateTrailingSL = 0.1;
input double SLPercentage = 0.02;


void OnTick()
{
//---
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   rsiHandle = iRSI(_Symbol, _Period, rsiPeriod, PRICE_CLOSE);
   atrHandle = iATR(_Symbol, _Period, atrPeriod);
   
   ArraySetAsSeries(rsiBuffer, true);
   ArraySetAsSeries(atrBuffer, true);
   
   CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer);
   CopyBuffer(atrHandle, 0, 0, 1, atrBuffer);
   
   
   //Filtres
   if(rsiBuffer[0] <= lowRsiTrigger)
   {
      canLong = true;
      canShort = false;
   }
   if(rsiBuffer[0] >= highRsiTrigger)
   {
      canShort = true;
      canLong = false;
   }
   
   //Conditions d'ouverture : LONG
   if(canLong 
   && PositionsTotal() == 0 
   && rsiBuffer[2] < lowRsiTrigger 
   && rsiBuffer[1] > lowRsiTrigger
   && rsiBuffer[0] > rsiBuffer[1])
   {
      SL = NormalizeDouble(Ask - SLATR * atrBuffer[0], _Digits);
      SLSize = SLATR * atrBuffer[0]; //--> Taille du SL en pips (Prix actuel - Position du SL)
      TP = NormalizeDouble(Ask + RRCoeff * SLSize, _Digits);
      CalcPositionSize(risk, SLSize);
      trade.Buy(vol, _Symbol, Ask, SL, TP, "Buy");
      //canLong = false;
      lastTradeType = "Green";
   }
   
   //Conditions d'ouverture : SHORT
   if(canShort 
   && PositionsTotal() == 0
   && rsiBuffer[2] > highRsiTrigger 
   && rsiBuffer[1] < highRsiTrigger
   && rsiBuffer[0] < rsiBuffer[1])
   {
      SL = NormalizeDouble(Bid + SLATR * atrBuffer[0], _Digits);
      SLSize = SLATR * atrBuffer[0]; //--> Taille du SL en pips (Prix actuel - Position du SL)
      TP = NormalizeDouble(Bid - RRCoeff * SLSize, _Digits);
      CalcPositionSize(risk, SLSize);
      trade.Sell(vol, _Symbol, Bid, SL, TP, "Sell");
      //canShort = false;
      lastTradeType = "Short";
   }
   
   //Gestion du trade ouvert
   
   /*if(PositionsTotal() == 1)
   {
      if(lastTradeType == "Long"
      && Ask - SL > SLSize + updateTrailingSL /100 * Ask)
      {
         SL = NormalizeDouble(Ask - SLSize, _Digits);
         trade.PositionModify(_Symbol, SL, 0);
      }
      
      if(lastTradeType == "Short"
      && SL - Bid > SLSize + updateTrailingSL /100 * Bid)
      {
         SL = NormalizeDouble(Bid + SLSize, _Digits);
         trade.PositionModify(_Symbol, SL, 0);
      }
   }*/
//--- 
}

//Fonctions 
//---
void CalcPositionSize(double r, double S){ // r = risk, S = SLSize

   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * r/100;
   S += (SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / 2;
   double riskPerPip = riskAmount / S;
   
   double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) / _Point;
   
   vol = NormalizeDouble(riskPerPip / pipValue, 1);
}
//---