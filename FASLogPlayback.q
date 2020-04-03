/ start IPC TCP/IP broadcast on port 6003 if not already enabled
\p 6003
/ upgrade HTTP protocol to websocket protocol
.z.ws:{neg[.z.w] -8! @[value;x;{`$ "'",x}]}

"Q Process running on port 6003 [websocket mode]"

hostPort: hsym `renxiang.cloud:5001:foorx:foorxaccess / cloud server
/ hostPort: hsym `localhost:5001:foorx:foorxaccess / local server
/ open IPC connection to server
h:hopen hostPort
flatDir: get `:flatDir
fullLog: get hsym `$flatDir,"fullLog"
/ //define gps and PID csv enlisting functions
/ enlistGPSCSV:{trimTable (x#"f";enlist csv) 0:y}
/ enlistPIDCSV:{trimTable (x#"f";enlist csv) 0:y}

/ / define table trim function
/ trimTable:{[inputTable] inputTable:(`$ssr[;" ";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"/";""] each trim each string cols inputTable)xcol inputTable;  inputTable:(`$ssr[;"_";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"(";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;")";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[; "[[]" ;""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[]]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[+]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[-]";""] each trim each string cols inputTable)xcol inputTable; inputTable:(`$ssr[;"[*]";""] each trim each string cols inputTable)xcol inputTable;inputTable:(`$ssr[;"[/]";""] each trim each string cols inputTable)xcol inputTable; :inputTable}

/ / convert table column to list
/ / t: table
/ / c: column index
/ / note that it returns list of list! apply raze after function call to simplify to list
/ / needed as we want to still keep strings for conversion to symbols
/ listFromTableColumn:{[t;c]raze each t[(cols t) c]}

/ / get directories
/ qDirectory: get `:qDirectory
/ dashboardDirectory: get `:dashboardDirectory
/ logsDirectory: get `:logsDirectory

/ system"cd ",logsDirectory

/ / read CSV containing files just uploaded to logs folder
/ logsListTable: ("I*";enlist csv) 0: `:logsManifest.csv
/ / remove non-valid rows
/ logsListTable: select from logsListTable where numColumns <> 0N
/ / select only files column from logsListTable and assign to logsList as list
/ logsList: `$listFromTableColumn[logsListTable;1]
/ / get feature count for each log
/ numFeaturesList: raze listFromTableColumn[logsListTable;0]

/ / create list indicating if log file is a gps log
/ isGPS: (0 ^ first each ss[;"?gps"] each string each logsList) > 0
/ / create list indicating if log file is a pid log
/ isPID: (0 ^ first each ss[;"?01.csv"] each string each logsList) > 0
/ / tabulate logs, # features in each log , if log is gps, if log is pid
/ logsListTable:([]numFeatures: numFeaturesList; Files:logsList;isGPS:isGPS; isPID:isPID) /create logsListTable

/ gpsLogsTable: select numFeatures,Files from logsListTable where isGPS = 1
/ pidLogsTable: select numFeatures,Files from logsListTable where isPID = 1

/ / listFromTableColumn function is defined in FASInit.q
/ gpsLogsNumFeatures: raze listFromTableColumn[gpsLogsTable;0]
/ pidLogsNumFeatures: raze listFromTableColumn[pidLogsTable;0]
/ gpsLogsFiles: raze listFromTableColumn[gpsLogsTable;1]
/ pidLogsFiles: raze listFromTableColumn[pidLogsTable;1]

/ / create new master table if splayed table didn't load
/ // add function to label each new log appended!
/ / if[not `GPSData in key`.; GPSData: enlistGPSCSV[first gpsLogsNumFeatures; first gpsLogsFiles];gpsLogsNumFeatures: 1_gpsLogsNumFeatures; gpsLogsFiles: 1_gpsLogsFiles] /use first log to initialise master table /drop first log already loaded

/ / build input from gps log files
/ numGPSFiles:count gpsLogsFiles
/ / read first gps log file
/ GPSDataInput:enlistGPSCSV[first gpsLogsNumFeatures; first gpsLogsFiles]; gpsLogsNumFeatures: 1_gpsLogsNumFeatures; gpsLogsFiles: 1_gpsLogsFiles
/ / if multiple pid log files are present, read the rest
/ if[numGPSFiles>1;{`GPSDataInput set GPSDataInput,enlistGPSCSV[(gpsLogsNumFeatures@x);(gpsLogsFiles@x)]} each til count gpsLogsNumFeatures]

/ / build input from pid log files
/ numPIDFiles:count pidLogsFiles
/ / read first pid log file
/ PIDDataInput: enlistPIDCSV[first pidLogsNumFeatures; first pidLogsFiles];pidLogsNumFeatures: 1_pidLogsNumFeatures; pidLogsFiles: 1_pidLogsFiles
/ if[numPIDFiles>1;{`PIDDataInput set PIDDataInput,enlistPIDCSV[(pidLogsNumFeatures@x);(pidLogsFiles@x)]} each til count pidLogsNumFeatures]

/ system"cd ",dashboardDirectory

/ fullLog:0!aj0[`timeus;GPSDataInput;PIDDataInput]
/ delete from `fullLog where rcCommand0=0N
/ / simulate mavlink input (json string)

/ /////data manipulation/////
/ update vbatLatestV:vbatLatestV*10 from `fullLog

/ convert to json string to simulate mavlink input format
mavlinkInputFormat:.j.j each 0! fullLog

/ require double colon to assign in place global variables
sendDatapoint: {if[count mavlinkInputFormat>0; {neg[h] (`processTelemetryStreamBuffer; x)} mavlinkInputFormat 0; mavlinkInputFormat::1_mavlinkInputFormat; show "Samples streamed: ",string (count fullLog) - count mavlinkInputFormat]}
.z.ts:{sendDatapoint[]}
\t 200