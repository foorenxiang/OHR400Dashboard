/
use with php upload interface
dependencies:
FAQUpdate.q
FAQUpdateModels.q
updateModels.p
useModels.p
\

/start IPC TCP/IP broadcast on port 5001 if not already enabled
\p 5001
/upgrade http protocol to websocket
.z.ws:{neg[.z.w] -8! @[value;x;{`$ "'",x}]}

/load embedpy
\l p.q

/load ml toolkit
\cd /Users/foorx/anaconda3/q
\l ml/ml.q
.ml.loadfile`:init.q;
"Machine Learning toolkit loaded"
"Q Process running on port 5001 [websocket mode]"

/switch back to q working folder
\cd /Users/foorx/Sites/OHR400Dashboard

//define gps and PID csv enlisting functions
enlistGPSCSV:{trimTable (x#"f";enlist csv) 0:y}
enlistPIDCSV:{trimTable (x#"f";enlist csv) 0:y}


//shorter trimTable function (WIP)
/trimColumn:{ssr[;" ";""];}
/trimTable:{[inputTable] inputTable:(`$ssr[;" ";""] each trim each string cols inputTable)xcol inputTable;}

//define table trim function
trimTable:{[inputTable] inputTable:(`$ssr[;" ";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"/";""] each trim each string cols inputTable)xcol inputTable;  inputTable:(`$ssr[;"_";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"(";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;")";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[; "[[]" ;""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[]]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[+]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[-]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[*]";""] each trim each string cols inputTable)xcol inputTable;inputTable:(`$ssr[;"[/]";""] each trim each string cols inputTable)xcol inputTable; :inputTable}

//convert table column to list
//t: table
//c: column index
//note that it returns list of list! apply raze after function call to simplify to list
//needed as we want to still keep strings for conversion to symbols
listFromTableColumn:{[t;c]raze each t[(cols t) c]}

/load master data
/attempt to load splayed master records table from disk if it exists
/ "loading stored GPS Dataset"
/ GPSData:get `:/Users/foorx/Sites/OHR400Dashboard/GPSData
/ "loading stored PID Dataset"
/ PIDData:get `:/Users/foorx/Sites/OHR400Dashboard/PIDData
/ "loading stored Joined Dataset"
/ fullLog:get `:/Users/foorx/Sites/OHR400Dashboard/fullLog
/ "loading stored Training Dataset"
/ trainingData: get `:/Users/foorx/Sites/OHR400Dashboard/trainingData


//ML functions
fac:{prd 1+til x} /define factorial function
pn:{[n;k] fac[n]%fac[n-k]} /define permutation function