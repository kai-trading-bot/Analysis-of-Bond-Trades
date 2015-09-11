%let path = T:\Khizar;															*Assign path to user;
libname Data "&path\Data"; 														*Assign the path to \Data;
%let _sdtm=%sysfunc(datetime()); 												*Begin timer because a secondary objective is to reduce runtime;

proc import datafile="T:\Khizar\2013-2014 Issues.csv" 
out=data.bondIssues
dbms=csv
replace;run;


proc import datafile="T:\Khizar\2013-2014 cusips.csv" 
out=bondCusips
dbms=csv
replace;run;


data tracetradesbyCusipsub;														*Create new dataset with truncated cusip containing all cusip-level data;											
	set data.TradesbyCusip;														
	length cusip2 $8;															*Initialize cusip length;
	cusip2=substr(cusip,1,8);													*Compustat uses 9-digit cusips, while CRSP uses 8-digit cusips;

run;
proc sort data=tracetradesbyCusipsub out=tracetradesbycusipsorted; by cusip2;	*Sort trades by cusip;
run;
data tradesbycusipmatches;merge data.bondissuessorted tracetradesbycusipsorted; *Create dataset with matched trades;
by cusip2; run;

data tradesbycusipfilter; set tradesbycusipmatches; 							*Define variables to retain from matched dataset ;
keep Cusip2 Price Description Yield_to_Mat Currency Issue_Date Yield Quantity EffectiveDate BenchmarkSpread TradeTypeCode YearData spreadCat matBucket yeartoMat countN endofday CusipID daysfromfirst countTdays ntrades retail tradeValue Volume frequency; run;
data tradesbycusipfilter2;set tradesbycusipfilter;by cusip2; 					*The trades belong to the Aggregate index if there is a value for YTM present;
if Yield_to_Mat ^=.; run;
data TradesbycusipFilter2;														*Set filtered dataset by cusip, date, and volume;
set TradesbycusipFilter2;
by Cusip2 EffectiveDate Volume;
proc sort data=tradesbycusipfilter2;by cusip2 EffectiveDate;run;				*Sort cusip-trimmed and filtered dataset by cusip and date;
proc sgplot data=Tradesbycusipfilter2;											*Scatter plot of maturity and frequency;
scatter x=yeartoMat y=frequency;
run;	
proc sgplot data=Tradesbycusipfilter2;											*Scatter plot of benchmark spread and frequency;
scatter x=benchmarkSpread y=frequency;
run;
proc sgplot data=Tradesbycusipfilter2;											*Scatter plot of maturity and volume;
scatter x=yeartoMat y=Volume;
run;
proc sgplot data=Tradesbycusipfilter2;											*Scatter plot of trading days and volume;
scatter x=countTdays y=Volume;
run;
data tracetradestrimsub;														*Create new dataset with truncated cusip containing all trade-level data;								
	set data.tracetradestrim;
	length cusip2 $8;															*Initialize cusip length to 8;
	cusip2=substr(cusip,1,8);													*Compustat uses 9-digit cusips, while CRSP uses 8-digit cusips;												
run;
proc sort data=tracetradestrimsub out=data.tracetradestrimsubsorted; by Cusip2; *Sort cusip-trimmed trades by cusip;
run;
proc sort data=data.bondIssues out=data.BondIssuesSorted; by Cusip2; run;		*Sort Barclays bond issues by cusip;
data TradeMatches;
	merge data.bondissuessorted data.tracetradestrimsubsorted;					*Merge sorted bond issues with cusip-trimmed trades on new cusip;
	by Cusip2;	
	run;

	data TradeMatchesFilter;													*Define variables to keep from matched/merged dataset of trades;											
	set TradeMatches; 
	keep Cusip2 Price Description Yield_to_Mat Currency Issue_Date Yield Quantity EffectiveDate BenchmarkSpread TradeTypeCode YearData spreadCat matBucket countN endofday CusipID daysfromfirst countTdays ntrades retail tradeValue Volume frequency;
	run;

data data.TradeMatchesFilter2;													*Identify trades for which YTM exists, which is unique to the US Barclays Aggregate;
set TradeMatchesFilter;
by Cusip2;
if Yield_to_Mat ^=.;
run;
proc sort data=data.TradeMatchesFilter2; by Cusip2 EffectiveDate; run;			*Sort matched and filtered trades by cusip and effectivedate;

data data.TradeMatchesFilter2;													*Mark end of day matched trades;
set data.TradeMatchesFilter2;
where endofday=1;
run;
data tryratiomarker;															*Create dataset with boolean for trading days >=90;
set data.tryratio2;
retain marker 1;																*Default value 1, 0 if fewer than 90 days of trading;
by cusip2;
syntheticday=(round((21/30)*daysfromfirst));									*Define a variable to account for trading days;					
if first.Cusip2
then do;
marker=syntheticday2>=90;														*Boolean for trading days >= 90;
end;
if first.Cusip2 then output;													*Repeat for each new cusip;
run;
data tryratiomarker2;															*Subset cusips for which minimum trading days condition is met;
set tryratiomarker; 
by cusip2;
where marker=1;
run;
data x;																			*Merge matched data with data for minimum trading days;
merge tryratiomarker2 data.tryratio2;
by cusip2;
run;
proc sort data=x; by cusip2 countTdays;run;										*Sort by count of trading days in ascending order;
data x2;
set x;
retain volumeRatio 1;															*Volume ratio is 1 for every cusip on the first day;
lagvol = lag(volume);															*Create variable for delayed volume;
if countTdays=1 then volumeRatio=1; 
*priceRatio=1;
if countTdays>=2 then do;														*On subsequent trading days, volume ratio is markov;
volumeRatio=volumeRatio*volume/lagvol;											
*priceRatio=priceRatio*price/lagprice;
end;
syntheticday2=(ceil((21/30)*daysfromfirst));									*Define variable for trading dats;
*if syntheticday2=0 then syntheticday2+1;
run;
proc sort data=x2;by syntheticday2;run;											*Sort adjusted data by count of trading days in ascending order;
proc means data=x2 noprint;
by syntheticday2;var volumeRatio;												*Calculate mean of volume ratios across cusips for each trading day;
output out=xvolumeRatioMean N=count mean=mean P10=p10 P25=p25 P50=p50 P75=p75 P90=p90 max=max min=min;
run; 
proc sort data=x2;by syntheticday2 benchmarkSpread;run;							*Sort adjusted data by benchmark spread in ascending order;
proc means data=x2 noprint;														*Calculate mean of volume ratios across cusips by credit spread;
by syntheticday2 benchmarkspread ;where benchmarkSpread>=0 & benchmarkSpread<=750;var volumeRatio;
output out=xvolumeRatioMeanMS N=count mean=mean P10=p10 P25=p25 P50=p50 P75=p75 P90=p90 max=max min=min;
run; 
proc g3d data=xvolumeRatioMeanMS;scatter syntheticday2*benchmarkSpread=p50 /	
	rotate=0 shape="pillar"; run;												*Surface plot of volume ratios across days and spread;								
symbol value=dot interpol=join;
title "Volume Ratio vs. Days of Trading";
footnote "Above is a plot of mean volume ratio for progressive trading days";
axis1 label=(angle=90 "mean Volume Ratio");
axis2 label=(angle=0 "Days of Trading");
proc sgplot data=xvolumeRatioMean;
reg x=syntheticday2 y=mean /  CLM CLI ;
run; 																			*Linear regression on means;
ods graphics on;
proc reg data=xvolumeRatioMean plots=predictions(x=syntheticday2);
var syntheticday2;											
model p50=syntheticday2 / r clm cli;
run;
ods graphics off;
ods graphics on; proc glm data=xvolumeRatioMean; model p50=syntheticday2; 		*Alternative procedure for linear regression;
run; ods graphics off;
 proc gplot data=xvolumeratiomean; plot syntheticday2*p50 /overlay;run;
proc sgplot data=xvolumeRatioMean;												*Concurrent plot of 10th and 50th percentile;
series x=syntheticday2 y=p10;
series x=syntheticday2 y=p50;
*series x=syntheticday2 y=p90;
run;
*Plot markup;
symbol value=dot interpol=join;
title "Volume Ratio vs. Days of Trading";
footnote "Above is a plot of 50p volume ratio for progressive trading days";
axis1 label=(angle=90 "p50 Volume Ratio");
axis2 label=(angle=0 "Days of Trading");
proc sgplot data=xvolumeRatioMean;scatter x=syntheticday2 y=p50;run;			*Plot median volume ratios across trading days;
symbol value=dot interpol=join;
title "Volume Ratio vs. Days of Trading";
footnote "";
axis1 label=(angle=90 "Mean Volume Ratio");
axis2 label=(angle=0 "Days of Trading");
proc sgplot data=xvolumeRatioMean ;
scatter x=syntheticday2 y=mean ;												*Plot mean volume ratios across trading days;
run; 
*Quadratic regression;
ods graphics on; proc glm data=xvolumeratiomean; model p50 = syntheticday2*syntheticday2;run; ods graphics off;
*Alternative Quadratic regression;
ods graphics on; proc glm data=xvolumeratiomeanMS plots(maxpoints=none); model p50 p90 = syntheticday2*syntheticday2  benchmarkSpread;run; ods graphics off;
*Initialize dataset for logistic regression;
data xvolumeratiolog;set xvolumeratiomean; logdays=log(syntheticday2);run;
*Logistic regression;
ods graphics on; proc glm data=xvolumeratiolog; model p50 = logdays;run; ods graphics off;
*Plot various distributions across trading days;
ods graphics on; proc glm data=xvolumeratiomean; model p10 = syntheticday2;run; ods graphics off;
ods graphics on; proc glm data=xvolumeratiomean; model p90 = syntheticday2;run; ods graphics off;
ods graphics on; proc glm data=xvolumeratiomean; model mean = syntheticday2;run; ods graphics off;




*For unique cusips, for illustratory purposes;
proc sgplot data=TradeMatchesFilter2;
where matBucket =0;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 

proc sgplot data=data.TradeMatchesFilter2;
*where matBucket =1;
where cusip2 = '001055AL';
	scatter x=countTdays y=ratio2;
run; 
proc sgplot data=TradeMatchesFilter2;
where matBucket =2;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 
proc sgplot data=TradeMatchesFilter2;
where matBucket =3;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 
proc sgplot data=TradeMatchesFilter2;
where matBucket =4;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 
proc sgplot data=TradeMatchesFilter2;
where matBucket =5;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 
proc sgplot data=TradeMatchesFilter2;
where spreadCat=1;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 

proc sgplot data=TradeMatchesFilter2;
where spreadCat=2;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 
proc sgplot data=TradeMatchesFilter2;
where spreadCat=3;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 
proc sgplot data=TradeMatchesFilter2;
where spreadCat=4;
*where cusip2 = '001055AL';
	scatter x=countTDays y=price;
run; 



*To isolate a specific ticker;
data TraceTradesTrimBAC;
set Data.TraceTradesTrim; where Ticker="BAC";
by Cusip;
run; 
