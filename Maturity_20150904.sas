*Khizar Qureshi, Research;
*This version: 2015-09-04;
******************************************************************************************************************************************************;
*Introduction;
******************************************************************************************************************************************************;

*The purpose of table2 is to create a table that displays the characteristics of trades across different maturities;
*The six types of maturities are: <1 year, 1-3 year, 3-5 year, 5-10 year, 10-20 year, 20+ year;
*The characteristics studied include:; 
*(1) Number of Trades, (2) Mean Trade Rate, (3) Trade Size in Value, (4) Trade Volume, (5) Frequency of days with a trade;
*The moments studied are: (1) mean and (2) standard deviation (later);
*These characteristics are across CUSIPS. We study across: (1) specific maturities, (2) overall;

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


/* Trade-Type */																	*Classification;
%let path = T:\Khizar;																*Assign path to user folder;
libname Data "&path\Data"; 															*Assign the path to \Data;
%let _sdtm=%sysfunc(datetime()); 													*Begin timer because a secondary objective is to reduce runtime;

proc sort data=Data.Tracetradestrim out=Data.Tracetradestrim; by Cusip matBucket; 	*Sort by cusip and classification;
run;
data Data.TraceTradestrim; 															*Data.Tracetradestrim will be the primary dataset;
set Data.Tracedaystrim; *where EffectiveDateTime >= '01Jan2014:00:00:00'DT; 		*To truncate the dataset for initial testing;														
by Cusip EffectiveDate; 															*sort by Cusips first since the summary stats are by cusip;	

* Count Trading days per cusip;
if lag(EffectiveDate)~= EffectiveDate then countTDays +1; 							*If consecutive effectivedates are distinguishable, increase the number of trading days by 1;
if first.EffectiveDate and first.Cusip then countTDays = 1;							*Set the number of trading days to 1 if it is the first day a new cusip is trading;

* Count time from first trade;
daysfromfirst + dif(EffectiveDateTime)/86400; 										*Divide by number of seconds in a day (86400=60*60*24);
if first.EffectiveDate and first.Cusip then daysfromfirst = 0; 						*If a new cusip is on its first effectivedate, set days from first day to zero;

* Count Number of Trades per cusip;
ntrades + 1; *Sum the trades;


if first.Cusip then do;
	ntrades=1; 																		*Initialize the number of trades on each new cusip to 1;
end;





tradeValue = Quantity*Price/100;													*TV=Price*Quantity/100;
							
Volume + tradeValue; 																*Update the volume by adding trade value;
Volume0 + tradeValue*(matBucket=0);
Volume1 + tradeValue*(matBucket=1);
Volume2 + tradeValue*(matBucket=2);
Volume3 + tradeValue*(matBucket=3);
Volume4 + tradeValue*(matBucket=4);
Volume5 + tradeValue*(matBucket=5);



if first.Cusip then do;																*For new cusips, begin to re-calculate volume;
Volume=tradeValue;
Volume0=tradeValue*(matBucket=0)/504;
Volume1=tradeValue*(matBucket=1)/504;
Volume2=tradeValue*(matBucket=2)/504;
Volume3=tradeValue*(matBucket=3)/504;
Volume4=tradeValue*(matBucket=4)/504;
Volume5=tradeValue*(matBucket=5)/504;
end;

run;

******************************************************************************************************************************************************;
*Summary Statistics;
******************************************************************************************************************************************************;

data tracetradestrim2;set data.tracetradestrim; 
dailytrades=ntrades/504;dailyvalue=tradeValue/504;frequency=countTdays/504;																									*The time frame is two years, or 504 trading days;
run;
data end; set tracetradestrim2; by cusip; where endofday=1; dailyvolume=volume/504;run;																						*Separate the finals trades of the day for volume aggregation;

proc means data=tracetradestrim2 noprint mean; class matBucket; var ntrades; output out=meantrades N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95; 			*Summarize Number of Trades;
run;
proc means data=tracetradestrim2 noprint mean; class matBucket; var dailytrades; output out=meandailytrades N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95; 	*Summarize Trade Rate;
run;
proc means data=tracetradestrim2 noprint mean; class matBucket; var dailyvalue; output out=meandailyvalue N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;	*Summarize Trade Value;
run;
proc means data=tracetradestrim2 noprint mean; class matBucket; var frequency; output out=frequency N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;			*Summarize frequency;
run;
proc means data=end noprint mean; class matBucket; var dailyvolume; output out=meandailyvolume N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;				*Summarize daily volume;
run;

%let _edtm=%sysfunc(datetime());																																			*This is the end of the timing process;
%let _runtm=%sysfunc(putn(&_edtm - &_sdtm, 12.4));
%put It took &_runtm second to run the program;

******************************************************************************************************************************************************;
*Export: Exports tables into MS Excel;
******************************************************************************************************************************************************;

proc export data=Work.meantrades
	outfile = "T:\Khizar\AvgTrades_Maturity.csv" 
	dbms=csv replace;
	run;

	proc export data=Work.meandailytrades
	outfile = "T:\Khizar\Rate_Maturity.csv" 
	dbms=csv replace;
	run;

proc export data=Work.meandailyvalue
	outfile = "T:\Khizar\Value_Maturity.csv" 
	dbms=csv replace;
	run;

proc export data=Work.meandailyvolume
	outfile = "T:\Khizar\Volume_Maturity.csv" 
	dbms=csv replace;
	run;

proc export data=Work.frequency
	outfile = "T:\Khizar\Frequency_Maturity.csv" 
	dbms=csv replace;
	run;

******************************************************************************************************************************************************;
*End;
******************************************************************************************************************************************************;
