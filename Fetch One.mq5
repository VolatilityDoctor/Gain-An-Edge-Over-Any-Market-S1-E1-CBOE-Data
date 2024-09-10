//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Gamuchirai Zororo Ndawana"
#property link      "https://www.mql5.com/en/users/gamuchiraindawa"
#property version   "1.00"
#property script_show_inputs

//+------------------------------------------------------------------+
//| Script Inputs                                                    |
//+------------------------------------------------------------------+
input int size = 100000; //How much data should we fetch?

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
int rsi_handler;
double rsi_buffer[];


//+------------------------------------------------------------------+
//| On start function                                                |
//+------------------------------------------------------------------+
void OnStart()
  {

//--- Load indicator
   rsi_handler = iRSI(_Symbol,PERIOD_CURRENT,20,PRICE_CLOSE);
   CopyBuffer(rsi_handler,0,0,size,rsi_buffer);
   ArraySetAsSeries(rsi_buffer,true);

//--- File name
   string file_name = "Market Data " + Symbol() + ".csv";

//--- Write to file
   int file_handle=FileOpen(file_name,FILE_WRITE|FILE_ANSI|FILE_CSV,",");

   for(int i= size;i>=0;i--)
     {
      if(i == size)
        {
         FileWrite(file_handle,"Time","Open","High","Low","Close","RSI");
        }

      else
        {
         FileWrite(file_handle,iTime(Symbol(),PERIOD_CURRENT,i),
                   iOpen(Symbol(),PERIOD_CURRENT,i),
                   iHigh(Symbol(),PERIOD_CURRENT,i),
                   iLow(Symbol(),PERIOD_CURRENT,i),
                   iClose(Symbol(),PERIOD_CURRENT,i),
                   rsi_buffer[i]
                  );

         Print("Time: ",iTime(Symbol(),PERIOD_CURRENT,i),"Close: ",iClose(Symbol(),PERIOD_CURRENT,i),"RSI",rsi_buffer[i]);
        }
     }
//--- Close the file
   FileClose(file_handle);
  }
//+------------------------------------------------------------------+
