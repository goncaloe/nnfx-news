//+------------------------------------------------------------------+
//|                                            NNFX_News_Offline.mq4 |
//|                                  Copyright 2020, Gonçalo Esteves |
//|                                      https://github.com/goncaloe |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, cryptek"
#property link      "https://github.com/goncaloe"
#property version   "1.00"
#property strict

#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1  clrTomato
#property indicator_color2  clrCornflowerBlue


enum DST {
   NO_DST=0,   // None
   US_DST=1,   // US DST
   EU_DST=2,   // European DST
   RU_DST=3,   // Russian DST
   AU_AEDT=4   // Australian AEDT
};

enum GMT {
   GMT_M12=-12,   // GMT-12
   GMT_M11=-11,   // GMT-11
   GMT_M10=-10,   // GMT-10
   GMT_M09=-9,    // GMT-09
   GMT_M08=-8,    // GMT-08
   GMT_M07=-7,    // GMT-07
   GMT_M06=-6,    // GMT-06
   GMT_M05=-5,    // GMT-05
   GMT_M04=-4,    // GMT-04
   GMT_M03=-3,    // GMT-03
   GMT_M02=-2,    // GMT-02
   GMT_M01=-1,    // GMT-01
   GMT_P00=0,     // GMT+00
   GMT_P01=1,     // GMT+01
   GMT_P02=2,     // GMT+02
   GMT_P03=3,     // GMT+03
   GMT_P04=4,     // GMT+04
   GMT_P05=5,     // GMT+05
   GMT_P06=6,     // GMT+06
   GMT_P07=7,     // GMT+07
   GMT_P08=8,     // GMT+08
   GMT_P09=9,     // GMT+09
   GMT_P10=10,    // GMT+10
   GMT_P11=11,    // GMT+11
   GMT_P12=12,    // GMT+12
};

input  GMT    GMTOffset = 0; // GMT offset
input  DST    DSTZone = 0; // DST setting
extern bool drawLine = true; // Draw Lines

string baseCurrency;
string quoteCurrency;
int startBar, endBar;

struct __news_event {
   datetime day;
   string event;
   int impact;
};


//buffers
double buffer1[];
double buffer2[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
   int len = StringLen(Symbol()); // for soft4fx
   baseCurrency = StringSubstr(Symbol(),len - 6,3);
   quoteCurrency = StringSubstr(Symbol(),len - 3,3);

   //--- indicator line
   SetIndexStyle(0,DRAW_ARROW,EMPTY,3, clrTomato);
   SetIndexArrow(0, 159);
   SetIndexBuffer(0, buffer1);
   SetIndexLabel(0, baseCurrency);

   SetIndexStyle(1,DRAW_ARROW,EMPTY,3, clrCornflowerBlue);
   SetIndexArrow(1, 159);
   SetIndexBuffer(1, buffer2);
   SetIndexLabel(1, quoteCurrency);

   IndicatorSetDouble(INDICATOR_MINIMUM, 0);
   IndicatorSetDouble(INDICATOR_MAXIMUM, 2);

   IndicatorShortName("NNFX News (" + baseCurrency + " / " + quoteCurrency + ")");

   drawLegend(baseCurrency, 8, 15, clrTomato);
   drawLegend(quoteCurrency, 8, 30, clrCornflowerBlue);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   if (drawLine){
      ObjectsDeleteAll(0, "News_H_");
   }
   return 0;
}


//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]){

   int Counted_bars;
   Counted_bars=IndicatorCounted();
   int limit = Bars-Counted_bars-1;

   if(limit == 0){
      return 0;
   }

   if(baseCurrency == "USD"){
      loadUSD(limit, 1);
   }
   else if(baseCurrency == "EUR"){
      loadEUR(limit, 1);
   }
   else if(baseCurrency == "GBP"){
      loadGBP(limit, 1);
   }
   else if(baseCurrency == "AUD"){
      loadAUD(limit, 1);
   }
   else if(baseCurrency == "CAD"){
      loadCAD(limit, 1);
   }
   else if(baseCurrency == "CHF"){
      loadCHF(limit, 1);
   }
   else if(baseCurrency == "JPY"){
      loadJPY(limit, 1);
   }
   else if(baseCurrency == "NZD"){
      loadNZD(limit, 1);
   }


   if(quoteCurrency == "USD"){
      loadUSD(limit, 2);
   }
   else if(quoteCurrency == "EUR"){
      loadEUR(limit, 2);
   }
   else if(quoteCurrency == "GBP"){
      loadGBP(limit, 2);
   }
   else if(quoteCurrency == "AUD"){
      loadAUD(limit, 2);
   }
   else if(quoteCurrency == "CAD"){
      loadCAD(limit, 2);
   }
   else if(quoteCurrency == "CHF"){
      loadCHF(limit, 2);
   }
   else if(quoteCurrency == "JPY"){
      loadJPY(limit, 2);
   }
   else if(quoteCurrency == "NZD"){
      loadNZD(limit, 2);
   }

   return 0;
}


void drawVLine(datetime d, string desc, int buff){
   string name = "News_H_" + TimeToStr(d,TIME_DATE|TIME_MINUTES);
   ObjectCreate(name,OBJ_VLINE,0,d,0);
   ObjectSet(name,OBJPROP_WIDTH,1);
   ObjectSet(name,OBJPROP_STYLE,STYLE_DOT);
   ObjectSet(name,OBJPROP_BACK,true);
   if(buff == 1){
      ObjectSet(name,OBJPROP_COLOR,clrPink);
      ObjectSetString(0,name,OBJPROP_TEXT,baseCurrency + ": " + desc);
   }
   else {
      ObjectSet(name,OBJPROP_COLOR,clrLightBlue);
      ObjectSetString(0,name,OBJPROP_TEXT,quoteCurrency + ": " + desc);
   }
}

void drawLegend(string currency, int xpos, int ypos, color dcolor){
   string rect_id = "News_H_leg_" + currency;
   if (ObjectFind(rect_id) != 0){
      ObjectCreate(rect_id, OBJ_RECTANGLE_LABEL, ChartWindowFind(), 0, 0);
   }
   ObjectSet(rect_id,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSet(rect_id,OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(rect_id, OBJPROP_BGCOLOR, dcolor);
   ObjectSet(rect_id, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(rect_id, OBJPROP_WIDTH, 0);
   ObjectSet(rect_id, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(rect_id,OBJPROP_XDISTANCE,xpos);
   ObjectSet(rect_id,OBJPROP_YDISTANCE,ypos);
   ObjectSet(rect_id, OBJPROP_XSIZE, 10);
   ObjectSet(rect_id, OBJPROP_YSIZE, 10);

   string lbl_id = "News_H_lab_" + currency;
   if (ObjectFind(lbl_id) != 0){
       ObjectCreate(lbl_id, OBJ_LABEL, ChartWindowFind(), 0, 0);
   }
   ObjectSet(lbl_id,OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(lbl_id,OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSet(lbl_id,OBJPROP_XDISTANCE,xpos + 10);
   ObjectSet(lbl_id,OBJPROP_YDISTANCE,ypos - 2);
   ObjectSetText(lbl_id, currency + " Events", 8, "Arial", dcolor);

}

int DSTOffset(datetime t, int DSTType) {
   if (isDST(t, DSTType)) {
      return 3600;
   }
   return 0;
}

bool isDST(datetime t, int zone = 0) {
   datetime dstStart;
   datetime dstEnd;
   if (zone == 2 || zone == 3) { // Europe & Russia
      if (zone == 3 && t > D'28.03.2011') return (false); // no DST for Russia after 28.03.2011
      dstStart = StrToTime((string)TimeYear(t) + ".03.31 01:00");
      while (TimeDayOfWeek(dstStart) != 0) { // last Sunday of March
         dstStart -= 3600 * 24;
      }
      dstEnd = StrToTime((string)TimeYear(t) + ".10.31 01:00");
      while (TimeDayOfWeek(dstEnd) != 0) { // last Sunday of October
         dstEnd -= 3600 * 24;
      }
      if (t >= dstStart && t < dstEnd) {
         return (true);
      }
      else {
         return (false);
      }
   }
   else if (zone == 1) { // US
      dstStart = StrToTime((string)TimeYear(t) + ".03.01 00:00"); // should be Saturday 21:00 GMT (New York is at GMT-5 and it changes at 2AM) but it doesn't really matter since we have no market during the weekend
      int sundayCount = 0;
      while (true) { // second Sunday of March
         if (TimeDayOfWeek(dstStart) == 0) {
            sundayCount++;
            if (sundayCount == 2) break;
         }
         dstStart += 3600 * 24;
      }
      dstEnd = StrToTime((string)TimeYear(t) + ".11.01 00:00");
      while (TimeDayOfWeek(dstEnd) != 0) { // first Sunday of November
         dstEnd += 3600 * 24;
      }
      if (t >= dstStart && t < dstEnd) {
         return (true);
      }
      else {
         return (false);
      }
   }
   else if (zone == 4) { // Australia
      datetime nonDstStart = StrToTime((string)TimeYear(t) + ".04.01 01:00");
      while (TimeDayOfWeek(nonDstStart) != 0) { // first Sunday of April
         nonDstStart += 3600 * 24;
      }
      datetime nonDstEnd = StrToTime((string)TimeYear(t) + ".10.01 01:00");
      while (TimeDayOfWeek(nonDstEnd) != 0) { // first Sunday of October
         nonDstEnd += 3600 * 24;
      }
      if (t >= nonDstStart && t < nonDstEnd) {
         return (false);
      }
      else {
         return (true);
      }
   }
   return (false);
}

void setNews(__news_event &news[], int limit, int buff){
   int size = ArraySize(news);
   int i, k;
   datetime d, sd;
   int val;

   if(Time[0] < news[0].day){
      return;
   }
   else if(Time[limit] > news[size - 1].day){
      return;
   }

   k = size - 1;
   for(i = 0; i <= limit; i++){
      d = Time[i];
      val = EMPTY_VALUE;
      while(k >= 0){
         while(true){
            if(k <= 0){
               break;
            }
            sd = news[k - 1].day;
            sd += GMTOffset * 3600;
            sd += DSTOffset(sd, DSTZone);

            if(sd < d){
               break;
            }
            k--;
         }
         sd = news[k].day;
         sd += GMTOffset * 3600;
         sd += DSTOffset(sd, DSTZone);

         if(sd >= d && sd < (d + PeriodSeconds())){
            val = 1;
            if (drawLine){
               drawVLine(sd, news[k].event, buff);
            }
         }
         break;
      }

      if(buff == 1){
         buffer1[i] = val;
      }
      else if(buff == 2){
         buffer2[i] = val;
      }
   }
}


// loadNews functions:
void loadUSD(int limit, int buff){
   static __news_event source[] = {
      {D'2010.01.03 15:30', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.01.06 13:15', "ADP Non-Farm Employment Change", 1},
      {D'2010.01.08 13:30', "Non-Farm Employment Change", 1},
      {D'2010.01.15 13:30', "Core CPI m/m", 1},
      {D'2010.01.15 13:30', "CPI m/m", 1},
      {D'2010.01.27 19:16', "FOMC Statement", 1},
      {D'2010.01.28 20:59', "Fed Chairman Nomination Vote", 1},
      {D'2010.02.03 13:15', "ADP Non-Farm Employment Change", 1},
      {D'2010.02.05 13:30', "Non-Farm Employment Change", 1},
      {D'2010.02.10 15:00', "Fed Chairman Bernanke Testifies", 1},
      {D'2010.02.19 13:30', "Core CPI m/m", 1},
      {D'2010.02.19 13:30', "CPI m/m", 1},
      {D'2010.02.24 15:00', "Fed Chairman Bernanke Testifies", 1},
      {D'2010.02.25 14:00', "Fed Chairman Bernanke Testifies", 1},
      {D'2010.03.03 13:15', "ADP Non-Farm Employment Change", 1},
      {D'2010.03.05 13:30', "Non-Farm Employment Change", 1},
      {D'2010.03.16 18:13', "FOMC Statement", 1},
      {D'2010.03.17 18:00', "Fed Chairman Bernanke Testifies", 1},
      {D'2010.03.18 12:30', "Core CPI m/m", 1},
      {D'2010.03.18 12:30', "CPI m/m", 1},
      {D'2010.03.20 13:00', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.03.25 14:00', "Fed Chairman Bernanke Testifies", 1},
      {D'2010.03.31 12:15', "ADP Non-Farm Employment Change", 1},
      {D'2010.04.02 12:30', "Non-Farm Employment Change", 1},
      {D'2010.04.07 17:30', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.04.09 00:30', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.04.13 23:00', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.04.14 12:30', "Core CPI m/m", 1},
      {D'2010.04.14 12:30', "CPI m/m", 1},
      {D'2010.04.14 14:00', "Fed Chairman Bernanke Testifies", 1},
      {D'2010.04.19 13:00', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.04.20 15:00', "Fed Chairman Bernanke Testifies", 1},
      {D'2010.04.21 14:15', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.04.27 14:00', "Fed Chairman Bernanke Testifies", 1},
      {D'2010.04.28 18:14', "FOMC Statement", 1},
      {D'2010.05.05 12:15', "ADP Non-Farm Employment Change", 1},
      {D'2010.05.06 13:30', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.05.07 12:30', "Non-Farm Employment Change", 1},
      {D'2010.05.08 13:30', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.05.13 16:30', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.05.19 12:30', "CPI m/m", 1},
      {D'2010.05.19 12:30', "Core CPI m/m", 1},
      {D'2010.05.26 00:30', "Fed Chairman Bernanke Speaks", 1},
      {D'2010.05.31 00:25', "Fed Chairman Bernanke Speaks", 1},
   };
   setNews(source, limit, buff);
};

void loadNZD(int limit, int buff){
   static __news_event source[] = {
      {D'2010.01.05 13:30', "GDT Price Index", 1},
      {D'2010.01.27 20:00', "Official Cash Rate", 1},
      {D'2010.02.02 13:30', "GDT Price Index", 1},
      {D'2010.02.03 21:45', "Employment Change q/q", 1},
      {D'2010.02.03 21:45', "Unemployment Rate", 1},
      {D'2010.03.02 13:30', "GDT Price Index", 1},
      {D'2010.03.10 20:00', "Official Cash Rate", 1},
      {D'2010.03.24 21:45', "GDP q/q", 1},
      {D'2010.04.06 14:30', "GDT Price Index", 1},
      {D'2010.04.28 21:00', "Official Cash Rate", 1},
      {D'2010.05.04 14:30', "GDT Price Index", 1},
      {D'2010.05.05 22:45', "Employment Change q/q", 1},
      {D'2010.05.05 22:45', "Unemployment Rate", 1},
   };
   setNews(source, limit, buff);
};

void loadCAD(int limit, int buff){
   static __news_event source[] = {
      {D'2010.01.08 12:00', "Unemployment Rate", 1},
      {D'2010.01.19 14:00', "BOC Rate Statement", 1},
      {D'2010.01.20 12:00', "Core CPI m/m", 1},
      {D'2010.01.20 12:00', "CPI m/m", 1},
      {D'2010.01.22 13:30', "Core Retail Sales m/m", 1},
      {D'2010.02.05 12:00', "Unemployment Rate", 1},
      {D'2010.02.18 12:00', "Core CPI m/m", 1},
      {D'2010.02.18 12:00', "CPI m/m", 1},
      {D'2010.02.19 13:30', "Core Retail Sales m/m", 1},
      {D'2010.03.02 14:00', "BOC Rate Statement", 1},
      {D'2010.03.12 12:00', "Unemployment Rate", 1},
      {D'2010.03.19 11:00', "Core CPI m/m", 1},
      {D'2010.03.19 11:00', "CPI m/m", 1},
      {D'2010.03.19 12:30', "Core Retail Sales m/m", 1},
      {D'2010.04.09 11:00', "Unemployment Rate", 1},
      {D'2010.04.20 13:00', "BOC Rate Statement", 1},
      {D'2010.04.23 11:00', "Core CPI m/m", 1},
      {D'2010.04.23 11:00', "CPI m/m", 1},
      {D'2010.04.23 12:30', "Core Retail Sales m/m", 1},
      {D'2010.05.07 11:00', "Unemployment Rate", 1},
      {D'2010.05.21 11:00', "Core CPI m/m", 1},
      {D'2010.05.21 11:00', "CPI m/m", 1},
      {D'2010.05.21 12:30', "Core Retail Sales m/m", 1},
   };
   setNews(source, limit, buff);
};

void loadEUR(int limit, int buff){
   static __news_event source[] = {
      {D'2010.01.11 10:16', "ECB President Trichet Speaks", 1},
      {D'2010.01.14 13:30', "ECB Press Conference", 1},
      {D'2010.01.21 12:00', "ECB President Trichet Speaks", 1},
      {D'2010.01.28 13:30', "ECB President Trichet Speaks", 1},
      {D'2010.02.04 13:30', "ECB Press Conference", 1},
      {D'2010.02.08 22:00', "ECB President Trichet Speaks", 1},
      {D'2010.03.04 13:30', "ECB Press Conference", 1},
      {D'2010.03.06 18:00', "ECB President Trichet Speaks", 1},
      {D'2010.03.10 18:00', "ECB President Trichet Speaks", 1},
      {D'2010.03.12 20:45', "ECB President Trichet Speaks", 1},
      {D'2010.03.19 07:45', "ECB President Trichet Speaks", 1},
      {D'2010.03.22 15:30', "ECB President Trichet Speaks", 1},
      {D'2010.03.25 08:00', "ECB President Trichet Speaks", 1},
      {D'2010.03.26 16:00', "ECB President Trichet Speaks", 1},
      {D'2010.04.08 12:30', "ECB Press Conference", 1},
      {D'2010.04.09 15:30', "ECB President Trichet Speaks", 1},
      {D'2010.04.10 07:45', "ECB President Trichet Speaks", 1},
      {D'2010.04.22 11:00', "ECB President Trichet Speaks", 1},
      {D'2010.04.26 16:30', "ECB President Trichet Speaks", 1},
      {D'2010.04.27 14:15', "ECB President Trichet Speaks", 1},
      {D'2010.04.27 17:15', "ECB President Trichet Speaks", 1},
      {D'2010.04.29 11:30', "ECB President Trichet Speaks", 1},
      {D'2010.05.06 12:30', "ECB Press Conference", 1},
      {D'2010.05.06 15:30', "ECB President Trichet Speaks", 1},
      {D'2010.05.10 12:45', "ECB President Trichet Speaks", 1},
      {D'2010.05.19 15:00', "ECB President Trichet Speaks", 1},
      {D'2010.05.31 00:30', "ECB President Trichet Speaks", 1},
      {D'2010.05.31 08:00', "ECB President Trichet Speaks", 1},
   };
   setNews(source, limit, buff);
};

void loadAUD(int limit, int buff){
   static __news_event source[] = {
      {D'2010.01.14 00:30', "Employment Change", 1},
      {D'2010.01.14 00:30', "Unemployment Rate", 1},
      {D'2010.02.02 03:30', "Cash Rate", 1},
      {D'2010.02.11 00:30', "Employment Change", 1},
      {D'2010.02.11 00:30', "Unemployment Rate", 1},
      {D'2010.03.02 03:30', "Cash Rate", 1},
      {D'2010.03.11 00:30', "Employment Change", 1},
      {D'2010.03.11 00:30', "Unemployment Rate", 1},
      {D'2010.04.06 04:30', "Cash Rate", 1},
      {D'2010.04.08 01:30', "Employment Change", 1},
      {D'2010.04.08 01:30', "Unemployment Rate", 1},
      {D'2010.05.04 04:30', "Cash Rate", 1},
      {D'2010.05.13 01:30', "Employment Change", 1},
      {D'2010.05.13 01:30', "Unemployment Rate", 1},
   };
   setNews(source, limit, buff);
};

void loadGBP(int limit, int buff){
   static __news_event source[] = {
      {D'2010.01.20 09:30', "MPC Official Bank Rate Votes", 1},
      {D'2010.01.26 09:30', "Prelim GDP q/q", 1},
      {D'2010.02.17 09:30', "MPC Official Bank Rate Votes", 1},
      {D'2010.03.17 09:30', "MPC Official Bank Rate Votes", 1},
      {D'2010.04.21 08:30', "MPC Official Bank Rate Votes", 1},
      {D'2010.04.23 08:30', "Prelim GDP q/q", 1},
      {D'2010.05.19 08:30', "MPC Official Bank Rate Votes", 1},
   };
   setNews(source, limit, buff);
};

void loadJPY(int limit, int buff){
   static __news_event source[] = {
      {D'2010.01.26 03:26', "Monetary Policy Statement", 1},
      {D'2010.02.18 02:45', "Monetary Policy Statement", 1},
      {D'2010.03.17 03:49', "Monetary Policy Statement", 1},
      {D'2010.04.07 03:03', "Monetary Policy Statement", 1},
      {D'2010.04.30 04:18', "Monetary Policy Statement", 1},
      {D'2010.05.10 03:11', "Monetary Policy Statement", 1},
      {D'2010.05.21 03:41', "Monetary Policy Statement", 1},
   };
   setNews(source, limit, buff);
};

void loadCHF(int limit, int buff){
   static __news_event source[] = {
      {D'2010.03.11 13:00', "Libor Rate", 1},
      {D'2010.03.11 13:00', "SNB Monetary Policy Assessment", 1},
   };
   setNews(source, limit, buff);
};

