* create library;
libname project 'C:\Users\wangx\Desktop\OPIM 5671 Data Mining\group project\walmart-recruiting-store-sales-forecasting';
run;

* final models and statistics calculation for total weekly sales of store 34;

***************************
* model1: additive seasonal;
proc esm data=project.Store34 back=20 lead=20 /* holdout sample=20, periods to forecast=20*/
		 plot=(corr errors modelforecasts) outstat=outstatS34_M1_addseasonal outfor=M1_forecast;
	id Date interval=week.6;
	forecast Total_Weekly_Sales / alpha=0.05 model=addseasonal transform=none;
run;
* MAPE=2.3%, 
AIC,SBC=409;

	* calculate the WMAE;
data WMAE_M1;
	set M1_forecast;
	where Date >='15JUN2012'd;
run;

proc sort data=project.allstores_ByDate;
	by Date;
proc sort data=WMAE_M1;
	by Date;
data WMAE_M1;
	merge WMAE_M1 project.allstores_ByDate;
	by Date;
run;

data WMAE_M1;
	set WMAE_M1;
	where ACTUAL~=.;
	if IsHoliday='TRUE' then w=5;
		else w=1;
	do;
	retain SUM_w WAE 0;
	SUM_w+w;
	WAE+w*abs(ERROR);
	WMAE=WAE/SUM_w;
	output;
	end;
run;
* WMAE=21527;



********************************
* model2: additive winters;
proc esm data=project.Store34 back=20 lead=20 /* holdout sample=20, periods to forecast=20*/
		 plot= (corr errors modelforecasts) outstat=outstatS34_M2_addseasonal outfor=M2_forecast;
	id Date interval=week.6;
	forecast Total_Weekly_Sales / alpha=0.05 model=addwinters transform=none;
run;
* MAPE=2.017%, 
AIC,SBC=404;

	* calculate the WMAE;
data WMAE_M2;
	set M2_forecast;
	where Date >='15JUN2012'd;
run;

proc sort data=project.allstores_ByDate;
	by Date;
proc sort data=WMAE_M2;
	by Date;
data WMAE_M2;
	merge WMAE_M2 project.allstores_ByDate;
	by Date;
run;

data WMAE_M2;
	set WMAE_M2;
	where ACTUAL~=.;
	if IsHoliday='TRUE' then w=5;
		else w=1;
	do;
	retain SUM_w WAE 0;
	SUM_w+w;
	WAE+w*abs(ERROR);
	WMAE=WAE/SUM_w;
	output;
	end;
run;
* WMAE=17289;



********************************************
* ARIMAX MODEL 1;
proc arima data=project.Store34
		   plots(only)=(forecast(forecast) residual(normal corr))
		   out=M3_forecast;
	identify var=Total_Weekly_Sales crosscorr=(Temperature IsHoliday_numeric MarkDown_2 MarkDown_3 MarkDown_5);
	estimate p=(0) q=(1,2,4) input=((1)Temperature 4 $ (11)IsHoliday_numeric 6 $ MarkDown_2 MarkDown_3 3 $ MarkDown_5) method=ML;
	forecast lead=20 back=20 interval=week.6 id=Date;
run;
* 3253, 3284----best mode3;

* accuracy of the model;

%include "&programloc";
%accuracy_prep(indsn=project.Store34,
			   series=Total_Weekly_Sales,
			   timeid=Date,
			   numholdback=&nhold);
run;

	* applying the final model3 to the ValidationSet;
proc arima data=ValidationSet
		   plots=none
		   out=M3_forecast;
	identify var=_y_fit crosscorr=(Temperature IsHoliday_numeric MarkDown_2 MarkDown_3 MarkDown_5);
	estimate p=(0) q=(1,2,4) input=((1)Temperature 4 $ (11)IsHoliday_numeric 6 $ MarkDown_2 MarkDown_3 3 $ MarkDown_5) method=ML;
	forecast lead=20 back=0 interval=week.6 id=Date nooutall;
run;

	* check accuracy of the validation set;
%accuracy (indsn=M3_forecast,
		   timeid=Date,
		   series=Total_Weekly_Sales,
		   numholdback=20,
		   forecast=forecast);
* MAPE=6.13%;
* WMAE=60290;



*******************************
* ARIMAX MODEL 2;
proc arima data=project.Store34
		   plots(only)=(forecast(forecast) residual(normal corr))
		   out=M4_forecast;
	identify var=Total_Weekly_Sales(52) crosscorr=(Unemployment MarkDown_3);
	estimate p=(0) q=(0) input=(Unemployment 3 $ MarkDown_3) method=ML;
	forecast lead=20 back=20 interval=week.6 id=Date;
run;
* 2170,2177;



	* accuracy of the model;

%include "&programloc";
%accuracy_prep(indsn=project.Store34,
			   series=Total_Weekly_Sales,
			   timeid=Date,
			   numholdback=&nhold);
run;

	* applying the final model4 to the ValidationSet;
proc arima data=ValidationSet
		   plots=none
		   out=M4_forecast;
	identify var=_y_fit(52) crosscorr=(Unemployment MarkDown_3);
	estimate p=(0) q=(0) input=((0) Unemployment 3 $ MarkDown_3) method=ML;
	forecast lead=20 back=0 interval=week.6 id=Date nooutall;
run;
	
%accuracy (indsn=M4_forecast,
		   timeid=Date,
		   series=Total_Weekly_Sales,
		   numholdback=20,
		   forecast=forecast);
* MAPE=2.05%;
* WMAE=18133;
