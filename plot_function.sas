%let path = T:\Khizar;																					*Assign path to user folder;
libname Data "&path\Data"; 																				*Assign the path to \Data;
%let _sdtm=%sysfunc(datetime()); 																		*Begin timer because a secondary objective is to reduce runtime;

proc sort data=Data.Tracetradestrim out=Data.Tracetradestrim; by Cusip matBucket; *spreadCat; run;		*Sort by Cusip, then maturity or spread;
data Data.TraceTradestrim; 																				*Data.Tracetradestrim will be the primary dataset;
set Data.Tracedaystrim; where EffectiveDateTime >= '01Oct2014:00:00:00'DT; 								*To truncate the dataset for initial testing;														
by Cusip EffectiveDate; 	
retail = .; 																							*Initialize retail to ., which means no value. This will be updated through conditioning;
if (TradeTypeCode = 'D') then retail = -1;  															*The trade type code indicates buyer (B), seller (S), or dealer (D);
else if Quantity >= 100000 then retail = 0; 															*Require an arbitrary minimum quantity for institutional (block) trades;
else retail = 1; 																						*All other trades are retail trades;
run;																									*remove if no control;*sort by Cusips first since the summary stats are by cusip;

data Data.TraceTradesHistogram; 																		*Histogram formation from all trades;
set Data.Tracetradestrim; *where yeartoMat<=30 & yeartoMat>=0 & benchmarkSpread<=750 & benchmarkSpread>=0 & EffectiveDateTime>='01Jan2014:00:00:00'DT &tradeValue<=1500000;	*To truncate the dataset for initial testing;														
run;

data Data.TraceTradesHistogram2; 																		*Histogram formation from all trades by cusip;
set Data.TradesByCusip; *where yeartoMat<=30 & yeartoMat>=0 & benchmarkSpread<=750 & benchmarkSpread>=0 & EffectiveDateTime>='01Jan2014:00:00:00'DT &tradeValue<=1500000;	*To truncate the dataset for initial testing;														
run;

data Data.TraceTradesHistogramD;																		*Histogram formation from all dealer trades;
set Data.TraceTradesHistogram; where retail=-1;
run;


data Data.TraceTradesHistogramR;																		*Histogram formation from all retail trades;
set Data.TraceTradesHistogram; where retail=1;
run;

data Data.TraceTradesHistogramI;																		*Histogram formation from all institutional type trades;
set Data.TraceTradesHistogram; where retail=0;
run;
ods graphics on;
proc kde data=data.TracetradesHistogram;																*Univariate histogram for credit spread;
		univar benchmarkSpread / plots=all;
run;
ods graphics off;

ods graphics on;
proc kde data=data.TracetradesHistogram;																*Univariate histogram for maturity;
		univar yeartoMat / plots=all;
run;
ods graphics off;

ods graphics on;
proc kde data=data.TracetradesHistogram;																*Univariate histogram for trade size in value;
	univar tradeValue / plots=all;
	run;
	ods graphics off;

ods graphics on;
proc kde data=data.TracetradesHistogram;																*Univariate histogram for trading days count;
univar countTDays / plots=all;
run;
ods graphics off;


ods graphics on;
proc kde data=data.TracetradesHistogramD;																*Univariate histogram for trading days for dealer trades;
univar countTDays / plots=all;
run;
ods graphics off;


ods graphics on;
proc kde data=data.TracetradesHistogramI;																*Univariate histogram for trading days for institutional trades;
univar countTDays / plots=all;
run;
ods graphics off;

ods graphics on;
proc kde data=data.TracetradesHistogramR;																*Univariate histogram for trading days for retail trades;
univar countTDays / plots=all;
run;
ods graphics off;


ods graphics on;
proc  kde data=data.TracetradesHistogram;																*Bivariate histogram for trade value and years to maturity;
	bivar tradeValue yeartoMat /plots=all;
	run;
	ods graphics off;

data Data.TraceTradesHistogram2;
set Data.tradesbycusip; where yeartoMat<=30 & yeartoMat>=0 & benchmarkSpread<=750 & benchmarkSpread>=0;	*Conditioned data for histogram;
run;

data data.TraceTradesHistogram2;																		*Frequency bins by cusip;
set data.TraceTradesHistogram2;
by Cusip EffectiveDate;
	IF frequency <=0.25 then freqBin=1;
	IF frequency >=0.25  and frequency<0.50 then freqBin=2;
	IF frequency >=0.50  and frequency<0.75 then freqBin=2;
	IF frequency >=0.75 and frequency<1 then freqBin=4;
	IF frequency >=1 then freqBin=5;
run;
proc sort data=data.TraceTradesHistogram2;																*Sort data for histogram by maturity;
by matBucket;
run;
proc rank data=data.TraceTradesHistogram2 out=HistogramRanks;
var matBucket;
ranks freqBin;
run;
proc print data=HistogramRanks;
run;


ods graphics on;
proc kde data=data.TracetradesHistogram2;
		bivar freqBin matBucket / plots=all;
		run;
		ods graphics off;

proc kde data=data.TracetradesHistogram2;
		bivar frequency yeartoMat;

		run;
 
	proc kde data=data.TracetradesHistogram;
		bivar yeartoMat benchmarkSpread / 
		out=count;
		run;
proc sort data=data.TraceTradesHistogram;
by yeartoMat;
run;
		proc means data=data.TracetradesHistogram noprint;
		var yeartoMat benchmarkSpread;
		output out=biVariate N=Count mean=Mean P1=P1 P5=P5 P25=P25 P50=P50 P75=P75 P95=P95;
		run; 
		proc sgplot data=data.TracetradesHistogram;
		histogram benchmarkSpread / binwidth=1 showbins scale=count;
		density benchmarkSpread;
		density benchmarkSpread / type=kernel;
		title 'benchmarkSpread vs. trade count';
		run;
proc sort data=data.TracetradesHistogram;by cusip;run;
proc freq data=data.TracetradesHistogram;
by cusip;
tables yeartoMat benchmarkspread;
output out=freqMatSpread;
run;


proc freq data=data.TracetradesHistogram2;
by cusip yeartoMat benchmarkSpread;
tables out;
output out=bivarSpread;
run;

	
		*timer; 												*This is the end of the timing process;
%let _edtm=%sysfunc(datetime());
%let _runtm=%sysfunc(putn(&_edtm - &_sdtm, 12.4));
%put It took &_runtm second to run the program;
