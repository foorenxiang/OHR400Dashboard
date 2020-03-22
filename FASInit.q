/
use with PHP upload interface
dependencies:
FAQUpdate.q
FAQUpdateModels.q
updateModels.p
useModels.p
\

/ start IPC TCP/IP broadcast on port 5001 if not already enabled
\p 5001
/ upgrade HTTP protocol to websocket protocol
.z.ws:{neg[.z.w] -8! @[value;x;{`$ "'",x}]}

\cd /Users/foorx/anaconda3/q
/ load embedpy
\l p.q

/ load ml toolkit
\l ml/ml.q
.ml.loadfile`:init.q;
"Machine Learning toolkit loaded"
"Q Process running on port 5001 [websocket mode]"

/ switch back to q working folder
\cd /Users/foorx/Sites/OHR400Dashboard

//define gps and PID csv enlisting functions
enlistGPSCSV:{trimTable (x#"f";enlist csv) 0:y}
enlistPIDCSV:{trimTable (x#"f";enlist csv) 0:y}

/ shorter trimTable function
/trimColumn:{ssr[;" ";""];}
/ trimTable:{[inputTable] inputTable:(`$ssr[;" ";""] each trim each string cols inputTable)xcol inputTable;}

/ define table trim function
trimTable:{[inputTable] inputTable:(`$ssr[;" ";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"/";""] each trim each string cols inputTable)xcol inputTable;  inputTable:(`$ssr[;"_";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"(";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;")";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[; "[[]" ;""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[]]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[+]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[-]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[*]";""] each trim each string cols inputTable)xcol inputTable;inputTable:(`$ssr[;"[/]";""] each trim each string cols inputTable)xcol inputTable; :inputTable}

/ convert table column to list
/ t: table
/ c: column index
/ note that it returns list of list! apply raze after function call to simplify to list
/ needed as we want to still keep strings for conversion to symbols
listFromTableColumn:{[t;c]raze each t[(cols t) c]}

/load master data
/attempt to load splayed master records table from disk if it exists
"Loading stored GPS Dataset"
/ GPSData: @[get;(`:/Users/foorx/Sites/OHR400Dashboard/GPSData);0N]
flatDir:"/Users/foorx/Sites/OHR400Dashboard/flat/"
GPSData: @[get;hsym `$flatDir,"GPSData";0N]
/ GPSData will store 0N if flat table is not found
if[(type GPSData)<90;delete GPSData from `.;0N!"Failed to load GPSData"]
"Loading stored PID Dataset"
/ PIDData: @[get;(`:/Users/foorx/Sites/OHR400Dashboard/PIDData);0N]
PIDData: @[get;hsym `$flatDir,"PIDData";0N] 
/ PIDData will store 0N if flat table is not found
if[(type PIDData)<90;delete PIDData from `.;0N!"Failed to load PIDData"]
"Loading stored Joined Dataset"
/ fullLog: @[get;(`:/Users/foorx/Sites/OHR400Dashboard/fullLog);0N]
fullLog: @[get;hsym `$flatDir,"fullLog";0N]
if[(type fullLog)<90;delete fullLog from `.;0N!"Failed to load fullLog"]
"Loading stored Training Dataset"
/ trainingData: @[get;(`:/Users/foorx/Sites/OHR400Dashboard/trainingData);0N]
trainingData: @[get;hsym `$flatDir,"trainingData";0N]
if[(type trainingData)<90;delete trainingData from `.;0N!"Failed to load trainingData"]
"Loading Predictions Table"
fullPredictionTable: @[get;hsym `$flatDir,"fullPredictionTable";0N]
if[(type fullPredictionTable)<90;delete fullPredictionTable from `.;0N!"Failed to load fullPredictionTable"]

/ check all tables are loaded correctly by checking for their presence in . namespace
allTablesLoaded:min {x in key `.} each `GPSData`PIDData`fullLog`trainingData

/prepare ticker function for ML batch training
tickerIterations:0
tickFreqMins:0.5
enableTimer:0 / enable timer(ticker function)
/ print success message if historical data on disk is successfully loaded
if[allTablesLoaded;0N!"All tables loaded!"]
/ define timer(ticker) callback function
.z.ts:{0N!"Automatic ML retraining triggered by timer!";system "l FASUpdateModels.q"}
/ if training data is already loaded, enable timer (ticker)
if[allTablesLoaded & enableTimer;0N!"Automatic ML retraining enabled!";system "t ",string tickFreqMins*60*1000]
if[not allTablesLoaded & enableTimer;0N!"Automatic ML retraining disabled!"]
delete tickFreqMins from `.; / delete tickFreqMinsvariable (no longer needed)
/ print error if could not load historical data on disk
if[not allTablesLoaded;0N!"Failure to load data from disk!"] 

saveCSVs:1b
if[saveCSVs; show "CSVs of tables will be saved"]
if[not saveCSVs; show "Not saving tables to CSVs"]

"Loading KX Developer"
\cd /Users/foorx/developer/
\l launcher.q_
\cd /Users/foorx/Sites/OHR400Dashboard

"System Up and Ready"

/ function definition to delete unneeded variables using functional sql
purgeTables: {system "rm GPSData PIDData fullLog trainingData"; varsToDelete:`GPSData`PIDData`fullLog`trainingData`varsToDelete;![`.;();0b;varsToDelete]};

/ ML functions
fac:{prd 1+til x} /define factorial function
pn:{[n;k] fac[n]%fac[n-k]} /define permutation function
/ if[((`trainingData in `.);(`trainingData in `.);(`trainingData in `.))]