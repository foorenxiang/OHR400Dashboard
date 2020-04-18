/ get directories
qDirectory: get `:qDirectory
dashboardDirectory: get `:dashboardDirectory

/ start IPC TCP/IP broadcast on port 5001 if not already enabled
\p 5001
/ upgrade HTTP protocol to websocket protocol
.z.ws:{neg[.z.w] -8! @[value;x;{`$ "'",x}]}

"Q Server Process running on port 5001 [websocket mode]"

//define gps and PID csv enlisting functions
enlistGPSCSV:{trimTable (x#"f";enlist csv) 0:y}
enlistPIDCSV:{trimTable (x#"f";enlist csv) 0:y}

/ define table trim function
trimTable:{[inputTable]
	inputTable:(`$ssr[;" ";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;"/";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;"_";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;"(";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;")";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[; "[[]" ;""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;"[]]";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;"[+]";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;"[-]";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;"[*]";""] each trim each string cols inputTable)xcol inputTable;
	inputTable:(`$ssr[;"[/]";""] each trim each string cols inputTable)xcol inputTable;
	:inputTable;}

/ convert table column to list
/ t: table
/ c: column index
/ note that it returns list of list! apply raze after function call to simplify to list
/ needed as we want to still keep strings for conversion to symbols
listFromTableColumn:{[t;c]raze each t[(cols t) c]}

/ function definition to delete unneeded variables using functional sql
purgeTables:{
	delete from `GPSData;
	delete from `PIDData;
	delete from `fullLog;
	delete from `trainingData;
	delete from `yPredTable;
	delete from `fullPredictionTable;}

/load master data
/attempt to load splayed master records table from disk if it exists
"Loading stored GPS Dataset"
flatDir:dashboardDirectory,"/flat/"
GPSData: @[get;hsym `$flatDir,"GPSData";0N]
/ GPSData will store 0N if flat table is not found
if[(type GPSData)<90;delete GPSData from `.;0N!"Failed to load GPSData"]
"Loading stored PID Dataset"
PIDData: @[get;hsym `$flatDir,"PIDData";0N] 
/ PIDData will store 0N if flat table is not found
if[(type PIDData)<90;delete PIDData from `.;0N!"Failed to load PIDData"]
"Loading stored Joined Dataset"
fullLog: @[get;hsym `$flatDir,"fullLog";0N]
if[(type fullLog)<90;delete fullLog from `.;0N!"Failed to load fullLog"]
"Loading stored Training Dataset"
trainingData: @[get;hsym `$flatDir,"trainingData";0N]
if[(type trainingData)<90;delete trainingData from `.;0N!"Failed to load trainingData"]
"Loading Predictions Table"
fullPredictionTable: @[get;hsym `$flatDir,"fullPredictionTable";0N]
if[(type fullPredictionTable)<90;delete fullPredictionTable from `.;0N!"Failed to load fullPredictionTable"]
"Loading Throttle Predictions Table"
yPredTable: @[get;hsym `$flatDir,"yPredTable";0N]
if[(type yPredTable)<90;delete yPredTable from `.;0N!"Failed to load yPredTable"]

/ check all tables are loaded correctly by checking for their presence in . namespace
allTablesLoaded:min {x in key `.} each `GPSData`PIDData`fullLog`trainingData

/ print success message if historical data on disk is successfully loaded
if[allTablesLoaded;0N!"All tables loaded!"]
/ print error if could not load historical data on disk
if[not allTablesLoaded;0N!"Failure to load data from disk!"] 

"Retrieving LSTM lookbackSteps from disk:"
show lookbackSteps: get `:lookbackSteps.dat 

saveCSVs:1b
if[saveCSVs; show "CSVs of tables will be saved"]
if[not saveCSVs; show "Not saving tables to CSVs"]

"Loading IPC definitions"
\l FASServerIPCDef.q

"Enabling immediate mode for Garbage Collection"
\g 1

/ save throttle predictions and trainingData to disk periodically
savehours: 1 / save yPredTable to disk after x hours
saveyPredTable:{(hsym `$flatDir,"yPredTable") set yPredTable;
	show "Throttle Predictions Table saved"}
saveTrainingData:{(hsym `$flatDir,"trainingData") set trainingData;
	show "Training Data Table saved"}
.z.ts:{saveyPredTable[]; saveTrainingData[]}
system"t ",string savehours*60*60*1000