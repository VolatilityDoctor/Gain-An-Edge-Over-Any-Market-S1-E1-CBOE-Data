//+------------------------------------------------------------------+
//|                                               EURXAU Fred AI.mq5 |
//|                                        Gamuchirai Zororo Ndawana |
//|                          https://www.mql5.com/en/gamuchiraindawa |
//+------------------------------------------------------------------+
#property copyright "Volatility Doctor"
#property link      "https://www.mql5.com/en/gamuchiraindawa"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Require the ONNX file                                            |
//+------------------------------------------------------------------+
#resource "\\Files\\XAUEUR FRED D1.onnx" as const uchar onnx_buffer[];

//+------------------------------------------------------------------+
//| Libraries                                                        |
//+------------------------------------------------------------------+
#include  <Trade/Trade.mqh>
CTrade Trade;

//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
long    onnx_model;
vector  mean_values  = vector::Zeros(6);
vector  std_values   = vector::Zeros(6);
vectorf model_inputs = vectorf::Zeros(6);
vectorf model_output = vectorf::Zeros(1);
double  bid,ask;
int     system_state,model_sate;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Load the ONNX model
   if(!load_onnx_file())
     {
      //--- We failed to load our ONNX model
      return(INIT_FAILED);
     }

//--- Load the scaling factors
   if(!load_scaling_factors())
     {
      //--- We failed to read in the scaling factors
      return(INIT_FAILED);
     }

//--- We mamnaged to load our model
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Free up the resources we no longer need
   release_resources();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Update market data
   fetch_market_data();

//--- Fetch a prediction from our model
   model_predict();

//--- If we have no positions follow the model's lead
   if(PositionsTotal() == 0)
     {
      //--- Buy position
      if(model_sate == 1)
        {
         if(iClose(Symbol(),PERIOD_W1,0) > iClose(Symbol(),PERIOD_W1,12))
           {
            Trade.Buy(0.3,Symbol(),ask,0,0,"XAUEUR Fred AI");
            system_state = 1;
           }
        };

      //--- Sell position
      if(model_sate == -1)
        {
         if(iClose(Symbol(),PERIOD_W1,0) < iClose(Symbol(),PERIOD_W1,12))
           {
            Trade.Sell(0.3,Symbol(),bid,0,0,"XAUEUR Fred AI");
            system_state = -1;
           }
        };
     }

//--- If we allready have positions open, let's manage them
   if(model_sate != system_state)
     {
      Trade.PositionClose(Symbol());
     }

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| This function will fetch a prediction from our model             |
//+------------------------------------------------------------------+
void model_predict(void)
  {
//--- Get the input data ready
   for(int i =0; i < 6; i++)
     {
      //--- The first 4 inputs will be fetched from the market
      matrix xau_eur_ohlc = matrix::Zeros(1,4);
      xau_eur_ohlc.CopyRates(Symbol(),PERIOD_D1,COPY_RATES_OHLC,0,1);
      //--- Fill in the data
      if(i<4)
        {
         model_inputs[i] = (float) ((xau_eur_ohlc[i,0] - mean_values[i])/ std_values[i]);
        }
      //--- We have to read in the fred alternative data
      else
        {
         read_fred_data();
        }
     }
  }

//+-------------------------------------------------------------------+
//| Read in the FRED data                                             |
//+-------------------------------------------------------------------+
void read_fred_data(void)
  {
//--- Read in the file
   string file_name = "fred_xau_eur.csv";

//--- Try open the file
   int result = FileOpen(file_name,FILE_READ|FILE_CSV|FILE_ANSI,","); //Strings of ANSI type (one byte symbols).

//--- Check the result
   if(result != INVALID_HANDLE)
     {
      Print("Opened the file");
      //--- Store the values of the file

      int counter = 0;
      string value = "";
      while(!FileIsEnding(result) && !IsStopped()) //read the entire csv file to the end
        {
         if(counter > 10)  //if you aim to read 10 values set a break point after 10 elements have been read
            break;          //stop the reading progress

         value = FileReadString(result);
         Print("Counter: ");
         Print(counter);
         Print("Trying to read string: ",value);

         if(counter == 3)
           {
            Print("Fred Euro data: ",value);
            model_inputs[4] = (float)((((float) value) - mean_values[4])/std_values[4]);
           }

         if(counter == 5)
           {
            Print("Fred Gold data: ",value);
            model_inputs[5] = (float)((((float) value) - mean_values[5])/std_values[5]);
           }

         if(FileIsLineEnding(result))
           {
            Print("row++");
           }

         counter++;
        }

      //--- Show the input and Fred data
      Print("Input Data: ");
      Print(model_inputs);

      //---Close the file
      FileClose(result);

      //--- Store the model prediction
      OnnxRun(onnx_model,ONNX_DEFAULT,model_inputs,model_output);
      Comment("Model Forecast",model_output[0]);
      if(model_output[0] > iClose(Symbol(),PERIOD_D1,0))
        {
         model_sate = 1;
        }

      else
        {
         model_sate = -1;
        }
     }

//--- We failed to find the file
   else
     {
      //--- Give the user feedback
      Print("We failed to find the file with the FRED data");
     }
  }

//+------------------------------------------------------------------+
//| Fetch market data                                                |
//+------------------------------------------------------------------+
void fetch_market_data(void)
  {
//--- Update the market data
   bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
  }

//+------------------------------------------------------------------+
//| Free up the resources we no longer need                          |
//+------------------------------------------------------------------+
void release_resources(void)
  {
//--- Free up all the resources we have used so far
   OnnxRelease(onnx_model);
   ExpertRemove();
   Print("Thank you for choosing Volatility Doctor");
  }

//+------------------------------------------------------------------+
//| Load our scaling factors                                         |
//+------------------------------------------------------------------+
bool load_scaling_factors(void)
  {
//--- Load the scaling values
   mean_values[0] = 1331.4964525595044;
   mean_values[1] = 1340.2280958591457;
   mean_values[2] = 1323.3776328659928;
   mean_values[3] = 1331.706768829475;
   mean_values[4] = 8.258127607767035;
   mean_values[5] = 16.35582438284101;
   std_values[0] = 329.7222075527991;
   std_values[1] = 332.11495530642173;
   std_values[2] = 327.732778866831;
   std_values[3] = 330.1146052811378;
   std_values[4] = 2.199782202942867;
   std_values[5] = 4.241112965400358;

//--- Validate the values loaded correctly
   if((mean_values.Sum() > 0) && (std_values.Sum() > 0))
     {
      return(true);
     }

//--- We failed to load the scaling values
   return(false);
  }

//+------------------------------------------------------------------+
//| Load the ONNX file                                               |
//+------------------------------------------------------------------+
bool load_onnx_file(void)
  {
//--- Create the ONNX model from the buffer we loaded earlier
   onnx_model = OnnxCreateFromBuffer(onnx_buffer,ONNX_DEFAULT);

//--- Validate the model we just created
   if(onnx_model == INVALID_HANDLE)
     {
      //--- Give the user feedback on the error
      Comment("Failed to create the ONNX model: ",GetLastError());
      //--- Break initialization
      return(false);
     }

//--- Define the I/O shape
   ulong input_shape [] = {1,6};

//--- Validate the input shape
   if(!OnnxSetInputShape(onnx_model,0,input_shape))
     {
      //--- Give the user feedback
      Comment("Failed to define the ONNX input shape: ",GetLastError());
      //--- Break initialization
      return(false);
     }

   ulong output_shape [] = {1,1};

//--- Validate the output shape
   if(!OnnxSetOutputShape(onnx_model,0,output_shape))
     {
      //--- Give the user feedback
      Comment("Failed to define the ONNX output shape: ",GetLastError());
      //--- Break initialization
      return(false);
     }

//--- We've finished
   return(true);
  }
//+------------------------------------------------------------------+
