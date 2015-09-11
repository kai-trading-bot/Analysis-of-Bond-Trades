# Analysis-of-Bond-Trades
*README.txt;
*Khizar Qureshi, Research;
*This version: 2015-09-04;
******************************************************************************************************************************************************;
*Introduction;
******************************************************************************************************************************************************;
The purposes of this package are: (1) The classification of bond trades stored recorded in the TRACE database, and (2) Model the liquidity of bonds 
following the issue date.

[1]
The three main types of means classification are: trade type, bond maturity, and bond credit spread. This package creates tables that summarize these
statistics across trades.

[2]
After an event, such as a debt issue, trading volume is expected to increase in the short term. After information is processed, expected trading 
volume decreases as a function of time.

volumeRatio represents the ratio of instantaneous trading volume to initial trading volume. We model the distribution of volumeRatio as a function
of time, maturity, and benchmark spread.

The set of trace trades is merged with the US Barclays Aggregate Index
******************************************************************************************************************************************************;
*Relevant syntax;
******************************************************************************************************************************************************;
Systemic:

data 		[Create new data file]
proc sort 	[Best available sorting algorithm]
proc means 	[Basic first moment/mean]
proc sgplot	[For scatter plots]
proc kde 	[For multivariate plots, distributions]
proc nlin	[For non-linear regression]
proc quantreg 	[For quantile regression]

Functional:

Merge		[Match (i.e. by Cusip)]
set		[Maintain or stack earlier version]
retain		[Set default value]	
keep		[Define the variables to keep in a set; drop rest]
model 		[Specify the model for regression]
parameters	[Specify parameters for non-linear regression]

******************************************************************************************************************************************************;
*Some terminology;
******************************************************************************************************************************************************;
CUSIP:		Unique ID of an issued bond
ntrades:	Number of trades
matBucket:	Maturity Category
spreadCat:	Credit Spread Category
retail:		Category for trade type
EffectiveDate:	Time of Trade
Endofday:	Boolean for last trade of day
daysfromfirst:	Days from first day of trade
countTdays:	Count of Trading Days
yeartoMat:	Continuous form of matBucket

******************************************************************************************************************************************************;
*Contents;
******************************************************************************************************************************************************;
I.read_data			Reads data from SQL
II. Trade_Type_20150904		Classification by trade type
III. Maturity_20150904		Classification by Maturity
IV.  Spread_20150904		Classification by Credit Spread
V. Liquidity_20150904		Liquidity Model
VI. Plot_function		Simple class plots
VII. Presentation_KQureshi	Slides			
******************************************************************************************************************************************************;
*Notes;

[1] We trim the data for outlier prices. Prices in: [80, 120]
[2] Minimum quantity for institutional type trade: 100,000
[3] There are missing bond credit spreads (see Spreadcat=.;)
[4] Because bond maturities are dynamic, we use only the maximum (initial) maturity
[5] Because bond credit spreads are dynamic, we use only the mean spread
******************************************************************************************************************************************************;


******************************************************************************************************************************************************;
*To-do List
******************************************************************************************************************************************************;
[1] Inference and classification of bonds with missing credit spreads
[2] Quantile regression on entire dataset conditioned on extrema spread, maturity
[3] 30-day volume buckets in liquidity study

******************************************************************************************************************************************************;
*Contact if needed;
*kqureshi@mit.edu;
******************************************************************************************************************************************************;
