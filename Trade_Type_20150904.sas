*Khizar Qureshi, Research;
*This version: 2015-09-04;
******************************************************************************************************************************************************;
*Introduction;
******************************************************************************************************************************************************;
*The purpose of table1 is to create a table that displays the characteristics of trades across different trade types;
*The three different types of trade are: retail, interdealer, and institutional;
*The characteristics studied include:; 
*(1) Number of Trades, (2) Mean Trade Rate, (3) Trade Size in Value, (4) Trade Volume, (5) Frequency of days with a trade;
*The moments studied are: (1) mean and (2) standard deviation (later);
*These characteristics are across CUSIPS. We study across: (1) specific trade types, (2) overall;

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
%let path = T:\Khizar;															*Assign path to user folder;
libname Data "&path\Data"; 														*Assign the path to \Data;
%let _sdtm=%sysfunc(datetime()); 												*Begin timer because a secondary objective is to reduce runtime;
proc sort data=Data.Tracetradestrim out=Data.Tracetradestrim; by Cusip retail; 	*Sort by cusip and classification;
run;
data Data.TraceTradestrim; 														*Data.Tracetradestrim will be the primary dataset;
set Data.Tracedaystrim; *where EffectiveDateTime >= '01Dec2014:00:00:00'DT; 	*To truncate the dataset for initial testing. Remove (*) for reducing sample;														
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


retail = .; 																	*Initialize retail to ., which means no value. This will be updated through conditioning below;
if (TradeTypeCode = 'D') then retail = -1;  									*The trade type code indicates buyer (B), seller (S), or interdealer (D);
else if Quantity >= 100000 then retail = 0; 									*Require an arbitrary minimum quantity for institutional (block) trades;
else retail = 1; *All other trades are retail trades;

;
tradeValue = Quantity*Price/100;												*TV=Price*Quantity/100;
							
Volume + tradeValue; 															*Update the volume by adding trade value throughout the trading day;
VolumeDealer + tradeValue*(retail=-1);
VolumeInst + tradeValue*(retail=0);
VolumeRetail + tradeValue*(retail=1);



if first.Cusip then do;															*For new cusips, begin to re-calculate volume;													
Volume=tradeValue;
VolumeDealer=tradeValue*(retail=-1);
VolumeInst=tradeValue*(retail=0);
VolumeRetail=tradeValue*(retail=1);
end;

run;	
******************************************************************************************************************************************************;
*Summary Statistics;
******************************************************************************************************************************************************;
		
data tracetradestrim2;set data.tracetradestrim; 
dailytrades=ntrades/504;dailyvalue=tradeValue/504;frequency=countTdays/504;																								*The time frame is two years, or 504 trading days;
run;
data end; set tracetradestrim2; by cusip; where endofday=1; dailyvolume=volume/504;run;																					*Separate the finals trades of the day for volume aggregation;
proc means data=tracetradestrim2 noprint mean; class retail; var ntrades; output out=meantrades N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95; 			*Summarize Number of Trades;
run;
proc means data=tracetradestrim2 noprint mean; class retail; var dailytrades; output out=meandailytrades N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95; *Summarize Trade Rate;
run;
proc means data=tracetradestrim2 noprint mean; class retail; var dailyvalue; output out=meandailyvalue N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;	*Summarize Trade Value;
run;
proc means data=tracetradestrim2 noprint mean; class retail; var frequency; output out=frequency N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;			*Summarize frequency;
run;
proc means data=end noprint mean; class retail; var dailyvolume; output out=meandailyvolume N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;				*Summarize daily volume;
run;	 																																								
%let _edtm=%sysfunc(datetime());																																		*This is the end of the timing process;
%let _runtm=%sysfunc(putn(&_edtm - &_sdtm, 12.4));
%put It took &_runtm second to run the program;
******************************************************************************************************************************************************;
*Export: Exports tables into MS Excel;
******************************************************************************************************************************************************;

*libname Data "&path\Data";
*EXPORT ROUTINES;
proc export data=Work.meantrades
	outfile = "T:\Khizar\AvgTrades_type.csv" 
	dbms=csv replace;
	run;
proc export data=Work.meandailytrades
	outfile = "T:\Khizar\Rate_type.csv" 
	dbms=csv replace;
	run;
proc export data=Work.meandailyvalue
	outfile = "T:\Khizar\Value_type.csv" 
	dbms=csv replace;
	run;
proc export data=Work.meandailyvolume
	outfile = "T:\Khizar\Volume_type.csv" 
	dbms=csv replace;	
	run;
proc export data=Work.frequency
	outfile = "T:\Khizar\Frequency_type.csv" 
	dbms=csv replace;
	run;
******************************************************************************************************************************************************;
*End;
******************************************************************************************************************************************************;
