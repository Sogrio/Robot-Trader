#include <Trade/Trade.mqh>
CTrade trade;

//Variables : Prix
datetime time[], currentTime;
double Ask, Bid, openPrice;

//Variables : Prise de position
double SL, SLSize;
double TP, TP1, TP2, TP3;
bool TP1Hit, TP2Hit, TP3Hit;
bool canLong, canShort;
double vol;
string lastTradeType;

//Variables : Candlesticks
double open[], high[], low[], close[];
double body, topWick, bottomWick;
string candleType;

//Variables : Indicateurs
int ema9Handle, ema18Handle, atrHandle;
double ema9Buffer[], ema18Buffer[], atrBuffer[];

//---

//Inputs (à configurer)
//---
input int ema9Period = 9;
input int ema18Period = 18;
input int atrPeriod = 5;
input double risk = 1.0;// en %
input double wickSize = 2.0;
input double SLATR = 1.5;
input double TP1Atr = 4.5;
input double TP2Atr = 9;
input double TP3Atr = 12;


void OnTick()
{
//---
   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   ema9Handle = iMA(_Symbol,_Period, ema9Period, 0, MODE_EMA, PRICE_CLOSE);
   ema18Handle = iMA(_Symbol, _Period, ema18Period, 0, MODE_EMA, PRICE_CLOSE);
   atrHandle = iATR(_Symbol, _Period, atrPeriod);
   
   ArraySetAsSeries(ema9Buffer, true);
   ArraySetAsSeries(ema18Buffer, true);
   ArraySetAsSeries(atrBuffer, true);
   
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   CopyBuffer(ema9Handle, 0, 0, 2, ema9Buffer);
   CopyBuffer(ema18Handle, 0, 0, 2, ema18Buffer);
   CopyBuffer(atrHandle, 0, 0, 1, atrBuffer);
   
   CopyOpen(_Symbol, _Period, 0, 2, open);
   CopyHigh(_Symbol, _Period, 0, 2, high);
   CopyLow(_Symbol, _Period, 0, 2, low);
   CopyClose(_Symbol, _Period, 0, 2, close);
   CopyTime(_Symbol, _Period, 0, 1, time);
   
   //Gestion du trade ouvert
   
   if(PositionsTotal() == 1)
   {
      if(lastTradeType == "Long")
      {
         if(Ask >= TP1 && TP1Hit == false)
         {
            TP1Hit = true;
            trade.PositionModify(_Symbol, openPrice, 0);
            trade.PositionClosePartial(_Symbol, vol/3);
         }
         
         if(Ask >= TP2 && TP2Hit == false)
         {
            TP2Hit = true;
            trade.PositionClosePartial(_Symbol, vol/3);
         }
         
         if(Ask >= TP3 && TP3Hit == false)
         {
            TP3Hit = true;
            trade.PositionClosePartial(_Symbol, vol/3);
         }
      }
      
      if(lastTradeType == "Short")
      {
         if(Bid <= TP1 && TP1Hit == false)
         {
            TP1Hit = true;
            trade.PositionModify(_Symbol, openPrice, 0);
            trade.PositionClosePartial(_Symbol, vol/2);
         }
         
         if(Bid <= TP2 && TP2Hit == false)
         {
            TP2Hit = true;
            trade.PositionClosePartial(_Symbol, vol/2);
         }
         
         if(Bid <= TP3 && TP3Hit == false)
         {
            TP3Hit = true;
            trade.PositionClosePartial(_Symbol, vol/3);
         }
      }
      
   }
   
   
   CopyBuffer(ema9Handle, 0, 0, 2, ema9Buffer);
   CopyBuffer(ema18Handle, 0, 0, 2, ema18Buffer);
   CopyBuffer(atrHandle, 0, 0, 1, atrBuffer);
   
   CopyOpen(_Symbol, _Period, 0, 2, open);
   CopyHigh(_Symbol, _Period, 0, 2, high);
   CopyLow(_Symbol, _Period, 0, 2, low);
   CopyClose(_Symbol, _Period, 0, 2, close);
   CopyTime(_Symbol, _Period, 0, 1, time);
   
   if(currentTime != time[0])
   {
      currentTime = time[0];
   }
   else
   {
      return;
   }
   
   //Bougies vertes
   if(close[1] > open[1])
   {
      candleType = "Green";
      topWick = high[1] - close[1];
      body = close[1] - open[1];
      bottomWick = open[1] - low[1];
   }
   
   //Bougies rouge
   if(close[1] < open[1])
   {
      candleType = "Red";
      topWick = high[1] - open[1];
      body = open[1] - close[1];
      bottomWick = close[1] - low[1];
   }
   
   //Filtres
   
   if(PositionsTotal() == 0 && ema18Buffer[0] > ema9Buffer[0])
   {
      canLong = true;
      canShort = false;
   }
   if(PositionsTotal() == 0 && ema9Buffer[0] > ema18Buffer[0])
   {
      canShort = true;
      canLong = false;
   }
   
   //Conditions d'ouverture : LONG
   if(canLong
   && candleType == "Green"
   && bottomWick >= wickSize * body 
   && topWick < body
   && PositionsTotal() == 0)
   {
      SL = NormalizeDouble(Ask - SLATR * atrBuffer[0], _Digits);
      SLSize = SLATR * atrBuffer[0]; //--> Taille du SL en pips (Prix actuel - Position du SL)
      TP1 = NormalizeDouble(Ask + TP1Atr * atrBuffer[0], _Digits);
      TP2 = NormalizeDouble(Ask + TP2Atr * atrBuffer[0], _Digits);
      TP3 = NormalizeDouble(Ask + TP3Atr * atrBuffer[0], _Digits);
      CalcPositionSize(risk, SLSize);
      openPrice = Ask;
      trade.Buy(vol, _Symbol, Ask, SL, TP1, "Buy");
      lastTradeType = "Long";
      TP1Hit = false;
      TP2Hit = false;
      TP3Hit = false;
   }
   
   //Conditions d'ouverture : SHORT
   if(canShort
   && candleType == "Red"
   && topWick >= wickSize * body 
   && bottomWick < body
   && PositionsTotal() == 0)
   {
      SL = NormalizeDouble(Bid + SLATR * atrBuffer[0], _Digits);
      SLSize = SLATR * atrBuffer[0]; //--> Taille du SL en pips (Prix actuel - Position du SL)
      TP1 = NormalizeDouble(Bid - TP1Atr * atrBuffer[0], _Digits);
      TP2 = NormalizeDouble(Bid - TP2Atr * atrBuffer[0], _Digits);
      TP3 = NormalizeDouble(Bid - TP3Atr * atrBuffer[0], _Digits);
      CalcPositionSize(risk, SLSize);
      openPrice = Bid;
      trade.Sell(vol, _Symbol, Bid, SL, TP1, "Buy");
      lastTradeType = "Short";
      TP1Hit = false;
      TP2Hit = false;
      TP3Hit = false;
   }
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
   
   if(MathMod(vol, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)*3) != 0)
   {
      vol = vol - MathMod(vol, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)*3);
   }
}
//---