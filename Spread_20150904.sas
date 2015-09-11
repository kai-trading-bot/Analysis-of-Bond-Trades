*Khizar Qureshi, Research;
*This version: 2015-09-04;
******************************************************************************************************************************************************;
*Introduction;
******************************************************************************************************************************************************;
*The purpose of table3 is to create a table that displays the characteristics of trades across different spreads;
*The four different types of spread are: <50 bps, 50-100 bps, 100-180 bps, 180+ bps. We mark missing trades with ".";
*The characteristics studied include:; 
*(1) Number of Trades, (2) Mean Trade Rate, (3) Trade Size in Value, (4) Trade Volume, (5) Frequency of days with a trade;
*The moments studied are: (1) mean and (2) standard deviation (later);
*These characteristics are across CUSIPS. We study across: (1) specific spreads, (2) overall;


******************************************************************************************************************************************************;
*Number of Trades: Defined as a count of trades;
******************************************************************************************************************************************************;
******************************************************************************************************************************************************;
*Trades per Day: Defined as the sum of all trades divided by the number of trading days;
******************************************************************************************************************************************************;
******************************************************************************************************************************************************;
*Trade Value: Defined as the transaction in value, as determined by a price and quantity of trade;
******************************************************************************************************************************************************;
******************************************************************************************************************************************************;
*Mean Dollar Volume: Defined as the aggregate trade value over the span of a time period;
******************************************************************************************************************************************************;
******************************************************************************************************************************************************;
*Trade Frequency: Defined as the proportion of days in which at least one trade occurred since the day of first trade;
******************************************************************************************************************************************************;
/* Trade-Type */																*Classification;
%let path = T:\Khizar;															*Assign the path to user folder;
libname Data "&path\Data"; 														*Assign the path to \Data;
%let _sdtm=%sysfunc(datetime()); 												*Begin timer because a secondary objective is to reduce runtime;

proc sort data=Data.Tracetradestrim out=Data.Tracetradestrim; by Cusip spreadCat; *Sort by cusip and classification;
run;
data Data.TraceTradestrim; 														*Data.Tracetradestrim will be the primary dataset;
set Data.Tracedaystrim; *where EffectiveDateTime >= '01Dec2014:00:00:00'DT; 	*To truncate the dataset for initial testing. Remove (*) for reducing sample ;														
by Cusip EffectiveDate; 														*sort by Cusips first since the summary stats are by cusip;
* Count Trading days per cusip;
if lag(EffectiveDate)~= EffectiveDate then countTDays +1; 						*If consecutive effectivedates are distinguishable, increase the number of trading days by 1;
if first.EffectiveDate and first.Cusip then countTDays = 1;						*Set the number of trading days to 1 if it is the first day a new cusip is trading;

* Count time from first trade;
daysfromfirst + dif(EffectiveDateTime)/86400; 									*Divide by number of seconds in a day (86400=60*60*24);
if first.EffectiveDate and first.Cusip then daysfromfirst = 0; 					*If a new cusip is on its first effectivedate, set days from first day to zero;

* Count Number of Trades per cusip;
ntrades + 1; *Sum the trades;


if first.Cusip then do;
	ntrades=1; 																	*Initialize the number of trades on each new cusip to 1;
end;


spreadCat = .;																	*Initialize spreadCat to ., which means no value. This will be updated through conditioning below;
  IF  benchmarkSpread <= 50 THEN spreadCat = 1;										*The spread code indicates the level of credit risk;
  IF (benchmarkSpread > 50) and (benchmarkSpread <=100) THEN spreadCat = 2;						
  IF (benchmarkSpread > 100) and (benchmarkSpread <=180) THEN spreadCat = 3;
  IF  benchmarkSpread > 180 THEN spreadCat = 4;
  If benchmarkSpread = . then spreadCat = -1;										*Missing spreads are labeled with -1. Therefore, when classifying by spread, negative moments originate from missing spreads;


tradeValue = Quantity*Price/100;												*TV=Price*Quantity/100;
							
Volume + tradeValue; 															*Update the volume by adding trade value;

Volume1 + tradeValue*(spreadCat=1);
Volume2 + tradeValue*(spreadCat=2);
Volume3 + tradeValue*(spreadCat=3);
Volume4 + tradeValue*(spreadCat=4);


if first.Cusip then do;															*For new cusips, begin to re-calculate volume;														
Volume=tradeValue;				

Volume1=tradeValue*(spreadCat=1);
Volume2=tradeValue*(spreadCat=2);
Volume3=tradeValue*(spreadCat=3);
Volume4=tradeValue*(spreadCat=4);


end;

run;
******************************************************************************************************************************************************;
*Adjusting for Mean Spread;
******************************************************************************************************************************************************;
proc sort data=data.tracetradestrim;by cusip;run;
proc means data=data.tracetradestrim noprint;
by cusip;
var benchmarkspread;
output out = meanBench mean=mean;												*Because each cusip has various benchmark spread, take mean;
run;
data benchMatchAll;														*Match trades with mean spread;
merge data.tracetradestrim meanbench;
by cusip; run;

data benchMatchAll2;set benchMatchAll;												*Need to assign mean benchmark spread to new spread categories;

spreadCat = .;															*Initialize the category for the spread;
  IF  benchmarkSpread <= 50 THEN spreadCat = 1;
  IF (benchmarkSpread > 50) and (benchmarkSpread <=100) THEN spreadCat = 2;
  IF (benchmarkSpread > 100) and (benchmarkSpread <=180) THEN spreadCat = 3;
  IF  benchmarkSpread > 180 THEN spreadCat = 4;
  If benchmarkSpread = . then spreadCat = -1;
run;
data benchMatch;														*Match end of day trades with mean spread;
merge data.endofcusip meanbench;												*Merge mean spread and end of day trades;
by cusip;
run; 

data benchMatch2;														*Analyze trades within benchmarkspread range (<=750 bps);
set benchMatch;
where benchmarkSpread<=750 & benchmarkSpread>=0 & yeartoMat<=30;
run;
******************************************************************************************************************************************************;
*Summary Statistics with Mean Spread;
******************************************************************************************************************************************************;
data tracetradestrim2;set data.tracetradestrim; 
dailytrades=ntrades/504;dailyvalue=tradeValue/504;frequency=countTdays/504;
run;
data end; set benchMatch; where endofday=1; dailyvolume=volume;run;												*Separate the finals trades of the day for volume aggregation;												
proc means data=benchMatchAll noprint mean; class spreadCat; var ntrades; output out=meantrades N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;			*Summarize Number of Trades;
run;
proc means data=benchMatchAll noprint mean; class spreadCat; var dailytrades; output out=meandailytrades N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;	*Summarize Trade Rate;
run;
proc means data=benchMatchAll noprint mean; class spreadCat; var dailyvalue; output out=meandailyvalue N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;	*Summarize Trade Value;
run;
proc means data=benchMatchAll noprint mean; class spreadCat; var frequency; output out=frequency N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;			*Summarize frequency;
run;
proc means data=end noprint mean; class spreadCat; var dailyvolume; output out=meandailyvolume N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;					*Summarize daily volume;
run;
******************************************************************************************************************************************************;
*Summary Statistics without Mean Spread;
******************************************************************************************************************************************************;
data tracetradestrim2;set data.tracetradestrim; 
dailytrades=ntrades/504;dailyvalue=tradeValue/504;frequency=countTdays/504;
run;
data end; set tracetradestrim2; by cusip; where endofday=1; dailyvolume=volume/504;run;												*Separate the finals trades of the day for volume aggregation;												
proc means data=tracetradestrim2 noprint mean; class spreadCat; var ntrades; output out=meantrades N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;			*Summarize Number of Trades;
run;
proc means data=tracetradestrim2 noprint mean; class spreadCat; var dailytrades; output out=meandailytrades N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;	*Summarize Trade Rate;
run;

proc means data=tracetradestrim2 noprint mean; class spreadCat; var dailyvalue; output out=meandailyvalue N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;	*Summarize Trade Value;
run;
proc means data=tracetradestrim2 noprint mean; class spreadCat; var frequency; output out=frequency N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;			*Summarize frequency;
run;
proc means data=end noprint mean; class spreadCat; var dailyvolume; output out=meandailyvolume N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;					*Summarize daily volume;
run;
******************************************************************************************************************************************************;
*Export: Exports tables into MS Excel;
******************************************************************************************************************************************************;

proc export data=Work.meantrades
	outfile = "T:\Khizar\AvgTrades_spread.csv" 
	dbms=csv replace;
	run;

	proc export data=Work.meandailytrades
	outfile = "T:\Khizar\Rate_spread.csv" 
	dbms=csv replace;
	run;

proc export data=Work.meandailyvalue
	outfile = "T:\Khizar\Value_spread.csv" 
	dbms=csv replace;
	run;

proc export data=Work.meandailyvolume
	outfile = "T:\Khizar\Volume_spread.csv" 
	dbms=csv replace;
	run;

proc export data=Work.frequency
	outfile = "T:\Khizar\Frequency_spread.csv" 
	dbms=csv replace;
	run;

******************************************************************************************************************************************************;
*End;
******************************************************************************************************************************************************;




	

























******************************************************************************************************************************************************;
*Trades per Day: Defined as the sum of all trades divided by the number of trading days;
******************************************************************************************************************************************************;
******************************************************************************************************************************************************;
*Arrival Rate: Defined as the sum of all trades divided by the number of days since the first trade;
******************************************************************************************************************************************************;
******************************************************************************************************************************************************;
*Trade Frequency: Defined as the proportion of days in which at least one trade occurred since the day of first trade;
******************************************************************************************************************************************************;



data Data.tradesByCusip;*interested in trades per cusip and arrival rate;
set benchMatchAll; where countTDays>=2;									*concatenate main data set;
by Cusip;																		*organize by cusip;

spreadCat = .;
  IF  benchmarkSpread <= 50 THEN spreadCat = 1;
  IF (benchmarkSpread > 50) and (benchmarkSpread <=100) THEN spreadCat = 2;
  IF (benchmarkSpread > 100) and (benchmarkSpread <=180) THEN spreadCat = 3;
  IF  benchmarkSpread > 180 THEN spreadCat = 4;
  If benchmarkSpread = . then spreadCat = -1;

ntrades1=ntrades*(spreadCat=1);
ntrades2=ntrades*(spreadCat=2);
ntrades3=ntrades*(spreadCat=3);
ntrades4=ntrades*(spreadCat=4);

*find Arrival rates with minimum number of trading days;
rateTrades = ntrades/daysfromfirst;												*once five trading days have passed, find arrival rate using updating number of trades and days;

rateTrades1=ntrades1/daysfromfirst;
rateTrades2=ntrades2/daysfromfirst;
rateTrades3=ntrades3/daysfromfirst;
rateTrades4=ntrades4/daysfromfirst;


*find trades per day with minimum number of trading days;
trades_day = ntrades/countTdays;												*divide number of total trades by number of total days of trading;
trades_day1=ntrades1/countTdays;
trades_day2=ntrades2/countTdays;
trades_day3=ntrades3/countTdays;
trades_day4=ntrades4/countTdays;


frequency = ntrades/(daysfromfirst);											*Frequency is defined as the fraction of trading days in which at least one trade occurs;


*output if all cusips considered;
if last.Cusip then output;														*end when the last recorded trade for a cusip is considered;
run;


data endbycusip;
set data.tradesbycusip; by cusip;where endofday=1;

rateTrades = ntrades/504;												*once five trading days have passed, find arrival rate using updating number of trades and days;

rateTrades1=ntrades1/504;
rateTrades2=ntrades2/504;
rateTrades3=ntrades3/504;
rateTrades4=ntrades4/504;


*find trades per day with minimum number of trading days;
trades_day = ntrades/countTdays;
												*divide number of total trades by number of total days of trading;
trades_day1=ntrades1/countTdays;
trades_day2=ntrades2/countTdays;
trades_day3=ntrades3/countTdays;
trades_day4=ntrades4/countTdays;

frequency = countTdays/(504);											*Frequency is defined as the fraction of trading days in which at least one trade occurs;



run;




proc sort data=Endbycusip out=Endbycusip; by Cusip spreadCat; run;
proc means data=Endbycusip noprint;
by cusip;
var frequency spreadCat;
output out=FrequencybyCusip mean(frequency)=mean_Frequency max(spreadCat)=spreadCat  N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
run;
proc sort data=frequencybycusip out=frequencybycusip;by spreadCat;run;
proc means data=FrequencybyCusip noprint;
by spreadCat;
var Mean_frequency;
output out =FreqDist N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
run; 
proc means data=Frequencybycusip noprint;
var Mean_frequency;
output out =FreqDistAll N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
run; 
*Arrival Rate;

proc sort data=endbycusip out=endbycusip ; by Cusip spreadCat; run;
proc means data=endbycusip  noprint;
by Cusip;
var rateTrades ratetrades1 ratetrades2 ratetrades3 ratetrades4 ;
output out=RatesbyCusip mean(ratetrades)=mean_rate mean(spreadCat)=mean_Spread N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
run;


proc sort data=endbycusip out=endbycusip ; by Cusip spreadCat; run;
proc means data=endbycusip  noprint;
by Cusip;
var trades_day  trades_day1 trades_day2 trades_day3 trades_day4 ;
output out=AvgbyCusip mean(trades_day)=mean_rate mean(spreadCat)=mean_Spread  N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
run;

proc sort data=RatesbyCusip;by mean_Spread; run;
proc means data=RatesbyCusip noprint;
by mean_Spread;
var Mean P1 P5 P25 P50 P75 P95 P95;
output out=RatesDist1 N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;;
run;

proc means data=RatesbyCusip noprint;
var Mean P1 P5 P25 P50 P75 P95 P95;
output out=RatesDist1All N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;;
run;

proc sort data=AvgbyCusip;by mean_Spread; run;
proc means data=RatesbyCusip noprint;
by mean_Spread;
var Mean P1 P5 P25 P50 P75 P95 P95;
output out=AvgDist1 N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;;
run;
proc means data=RatesbyCusip noprint;
var Mean P1 P5 P25 P50 P75 P95 P95;
output out=AvgDist1All N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;;
run; 


******************************************************************************************************************************************************;
*Trade Value: Defined as the transaction in value, as determined by a price and quantity of trade;
******************************************************************************************************************************************************;

proc sort data=Data.Tracetradestrim out=Data.Tracetradestrim; by Cusip spreadCat; run;

proc means data = Data.Tracetradestrim noprint;										*Refer to main dataset;
by Cusip spreadCat;	
var tradeValue;																		*Interested in trade value across spreads;
output out = valuebyCusip mean(tradeValue)=Val_bar mean(spreadCat)=mean_Spread;  								*find mean of trade value.;
run;
data value1; set valuebyCusip; where spreadCat=1; run;							*Isolate spreads;
data value2; set valuebyCusip; where spreadCat=2; run;							*Isolate spreads;
data value3; set valuebyCusip; where spreadCat=3; run;							*Isolate spreads;
data value4; set valuebyCusip; where spreadCat=4; run;							*Isolate spreads;

proc means data=value1 noprint; 												*Consider the mean trade value across spreads;	
var Val_bar;
output out= distVal1 N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;					*Output the distribution of mean trade value by spreads;
run;

proc means data=value2 noprint; 												*Consider the mean trade value across spreads;	
var Val_bar;
output out= distVal2 N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;					*Output the distribution of mean trade value by spreads;
run;

proc means data=value3 noprint; 												*Consider the mean trade value across spreads;	
var Val_bar;
output out= distVal3 N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;					*Output the distribution of mean trade value by spreads;
run;

proc means data=value4 noprint; 												*Consider the mean trade value across spreads;	
var Val_bar;
output out= distVal4 N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;					*Output the distribution of mean trade value by spreads;
run;



proc means data=valuebyCusip noprint; 												*Consider the mean trade value across spreads;	
var Val_bar;
output out= distVal N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;					*Output the distribution of mean trade value by spreads;
run;

data valDist; set distVal  distVal1 distVal2 distVal3 distVal4 ; run;						*Stack each distribution;

******************************************************************************************************************************************************;
*Mean Dollar Volume: Defined as the aggregate trade value over the span of a time period;
******************************************************************************************************************************************************;
*Volume=Cumulative intraday trade Value;

data Data.endofDayVolume; set data.tradesbycusip; where endofday=1;run;			*Count volume only at end of day;

proc sort data=Data.endofdayvolume out=Data.endofdayvolume; by Cusip spreadCat; run;	*Sort tracetradestrim to prepare for mean by cusip;
proc means data=Data.endofDayVolume noprint;
by Cusip;
var Volume  Volume1 Volume2 Volume3 Volume4 spreadCat;									*Study trade type volume at end of day;
output out = volumebyCusip mean(Volume)=mean_Volume mean(SpreadCat)=mean_Spread N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
run;

proc sort data=VolumebyCusip out=VolumebyCusip; by mean_Spread; run; *Only averages;
proc means data=VolumebyCusip noprint;
by mean_Spread;
var Mean P1 P5 P25 P50 P75 P95 P95;
output out=VolumeDist1 N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;;
run;

proc means data=VolumebyCusip noprint;
var Mean P1 P5 P25 P50 P75 P95 P95;
output out=VolumeDist1All N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
run;



******************************************************************************************************************************************************;
*Number of Trades: Defined as a count of trades;
******************************************************************************************************************************************************;

*Number of Trades;
*Counting trades across each spread category;
proc sort data=Data.tracetradestrim out=Data.tracetradestrim; by spreadCat;run;
proc means data=Data.tracetradestrim noprint mean;
class spreadCat;
var Ntrades;
output out = Data.distrTradesbyCusip N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
run;
data tradeDist; set Data.distrTradesbyCusip; run; 













	proc univariate data=data.Tracetradestrim noprint;
	var Ntrades benchmarkSpread;
	histogram
			/midpoints=0 to 5000 by 1;
	run;




*timer; 												*This is the end of the timing process;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysfunc(putn(&_edtm - &_sdtm, 12.4));
%put It took &_runtm second to run the program;

















******************************************************************************************************************************************************;
*Export: Exports tables into MS Excel;
******************************************************************************************************************************************************;

*libname Data "&path\Data";
*EXPORT ROUTINES;
proc export data=Work.AvgDist1
	outfile = "T:\Khizar\AvgTrades_spread.csv" 
	dbms=csv replace;
	run;

proc export data=Work.RatesDist1
	outfile = "T:\Khizar\Rates_spread.csv" 
	dbms=csv replace;
	run;



proc export data=Work.ValDist
	outfile = "T:\Khizar\Value_spread.csv" 
	dbms=csv replace;
	run;

proc export data=Work.VolumeDist1
	outfile = "T:\Khizar\Volume_spread.csv" 
	dbms=csv replace;
	run;

proc export data=Work.Freqdist
	outfile = "T:\Khizar\Frequency_spread.csv" 
	dbms=csv replace;
	run;

proc export data=Work.tradeDist
	outfile = "T:\Khizar\Trades_spread.csv"
	dbms=csv replace;
	run;



	
proc export data=Work.VolumeDist1All
	outfile = "T:\Khizar\Volume_Spread_All.csv" 
	dbms=csv replace;
	run;

proc export data=Work.FreqdistAll
	outfile = "T:\Khizar\Frequency_Spread_All.csv" 
	dbms=csv replace;
	run;
proc export data=Work.AvgDist1All
	outfile = "T:\Khizar\AvgTrades_Spread_All.csv" 
	dbms=csv replace;
	run;

proc export data=Work.RatesDist1All
	outfile = "T:\Khizar\Rates_Spread_All.csv" 
	dbms=csv replace;
	run;




** Overall Output--Not by class;










