 /* ACCURACY_PREP */


/* The %ACCURACY_PREP macro requires 4 arguments: */

/* INDSN=      The name of the dataset output from the SAS/ETS forecasting procedure */

/* SERIES=     The name of the target series */

/* TIMEID=     The name of the time variable */

/* NUMHOLDBACK=The number of time points for the holdout sample */


%macro accuracy_prep(indsn=,series=,timeid=,numholdback=);


proc sort data=&indsn out=ValidationSet;

    by descending &timeid;

run;


data ValidationSet;

    set ValidationSet;

    _y_fit=&series;

    _y_holdout=&series;

    if _n_<=&numholdback then _y_fit=.;

    else _y_holdout=.;

run;


proc sort data=work.ValidationSet;

    by &timeid;

run;


%mend accuracy_prep;


/* ACCURACY macro */


/* The %ACCURACY macro requires 4 arguments: */

/* INDSN=      The name of the dataset output from the SAS/ETS forecasting procedure */

/* SERIES=     The name of the target series */

/* TIMEID=     The name of the time variable */

/* NUMHOLDBACK=The number of time points for the holdout sample */

%macro accuracy(indsn=,timeid=,series=,numholdback=,forecast=forecast);


    data &indsn._ACC(keep=Series Model MAPE MAE MSE RMSE WMAE _N);

        length Model $2000;

        merge &indsn(in=f) work.ValidationSet end=eof;

        by &timeid;
        
        if IsHoliday='TRUE' then w=5;
            	else w=1;
        
        

        if f;

     
        retain APE AE SSE _N SUM_w WAE 0;

        label _N="Holdback Periods";
 
       
        APE+abs((&series-&Forecast)/&series);

        AE+abs(&series-&Forecast);

        SSE+(&series-&Forecast)**2;

        _N+n(&series);
        
        SUM_w+w;
        
        WAE+w*abs(&series-&Forecast);
        

        
        format MAPE percent10.2;

        
        if eof then do;

            MAPE=APE/_N;

            MAE=AE/_N;

            MSE=SSE/_N;

            RMSE=MSE**0.5;
            
            WMAE=WAE/SUM_w;
			
            Model="&indsn";

            Series="&series";

            output;

        end;


    run;


/* The data set is printed. */

    proc print data=&indsn._ACC label;

        id Series;

    run;

    
%mend accuracy;



