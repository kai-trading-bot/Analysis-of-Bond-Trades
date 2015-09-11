/* ===== Connect to Terminal ===== */
LIBNAME sql ODBC 
NOPROMPT = "uid=kqureshi; DSN=DFAResearch; SERVER=ASTDC-SQL09P; DATABASE=DFAResearch;" ;

* check that works;
*proc print Data = sql.TRACEData2013 (obs=10);
*run;

* Read in Some Data; 
Data TRACE2013;
set sql.TRACEData2013;
yearData = 2013;
run;

Data TRACE2014;
set sql.TRACEData2014;
yearData =2014;
run;

* Remove some overalapping data;
Data TRACE2013Year;
set TRACE2013;
where Quantity>0;
if EffectiveDateTime >= '01Jan2013:00:00:00'DT and EffectiveDateTime<='31Dec2013:00:00:00'DT;
run;

Data TRACE2014Year;
set TRACE2014;
where Quantity>0;
if EffectiveDateTime >= '01Jan2014:00:00:00'DT and EffectiveDateTime <='31Dec2014:00:00:00'DT;
run;

data TRACE1314;
set TRACE2013Year TRACE2014Year;
where price>(104.78-20.75) and price<(104.78+20.75);
monthVar = year(datepart(EffectiveDate))+month(datepart(EffectiveDate))/100;
run;

* Combine Two Years of data;
proc sort data= TRACE1314 out=TRACE1314;
by Cusip EffectiveDate;
run;

*** Calculate price changes data;
%let path = T:\Khizar;
libname Data "&path\Data";

data Data.TraceP;
set Trace1314; 
where Quantity>0;
by Cusip EffectiveDate;
* price change;
deltaP = dif(Price);
* timebetween trades;
deltaT = dif(EffectiveDateTime);
if first.EffectiveDate then do; 
deltap = .;
deltat = .;
end;

* Categorize by spread value;
spreadCat = .;
  IF  benchmarkSpread <= 50 THEN spreadCat = 1;
  IF (benchmarkSpread > 50) and (benchmarkSpread <=100) THEN spreadCat = 2;
  IF (benchmarkSpread > 100) and (benchmarkSpread <=180) THEN spreadCat = 3;
  IF  benchmarkSpread > 180 THEN spreadCat = 4;
  If benchmarkSpread = . then spreadCat = -1;

* Maturity buckets variable, in years;
yearToMat = (Maturity - EffectiveDate)/(86400*365);
matBucket = .;
if yearToMat <= 1 then matBucket = 0;
if (yearToMat > 1) and (yearToMat <= 3) then matBucket = 1;
if (yearToMat > 3) and (yearToMat <= 5) then matBucket = 2;
if (yearToMat >5) and (yearToMat <=10) then matBucket = 3;
if (yearToMat >10) and (yearToMat <=15) then matBucket=4;
if (yearToMat >15) and (yearToMat <=20) then matBucket=5;
if (yearToMat >20) then matBucket = 6;

* Count trades within a day;
countN+1;
if first.EffectiveDate then countN=1;
if last.EffectiveDate  then endofday=1; else endofday=0;

* CusipID;
retain cusipID 0;
if first.cusip and first.effectiveDate then cusipID +1;
drop unused variables;
keep Cusip Ticker EffectiveDate EffectiveDateTime Price deltap deltaT Yield Quantity BenchmarkSpread Maturity TradeTypeCode monthVar yearToMat matBucket countN endofday cusipID YearData;

run;

/* Add number of trading days count*/
proc sort data=Data.Tracep; by EffectiveDate;run;
data Data.TraceDays;
set Data.Tracep;
if lag(EffectiveDate)~=EffectiveDate then daysN +1;
run;


proc sort data = Data.TraceDays; by Cusip EffectiveDate;run;
