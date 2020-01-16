///////////////////////
/ Filter parameters
minSpeedForFilter: 60 /in kph
///////////////////////


\cd /Users/foorx/logs
/ read CSV containing files just uploaded to logs folder
logsListTable: ("I*";enlist csv) 0: `:logsManifest.csv
/ remove non-valid rows
logsListTable: select from logsListTable where numColumns <> 0N
/ select only files column from logsListTable and assign to logsList as list
logsList: `$listFromTableColumn[logsListTable;1]
numFeaturesList: raze listFromTableColumn[logsListTable;0]

/ write function that determines if it is a GPS or PID csv!!
isGPS: (0 ^ first each ss[;"?gps"] each string each logsList) > 0
isPID: (0 ^ first each ss[;"?01.csv"] each string each logsList) > 0
logsListTable:([]numFeatures: numFeaturesList; Files:logsList;isGPS:isGPS; isPID:isPID) /create logsListTable

gpsLogsTable: select numFeatures,Files from logsListTable where isGPS = 1
pidLogsTable: select numFeatures,Files from logsListTable where isPID = 1
gpsLogsNumFeatures: raze listFromTableColumn[gpsLogsTable;0]
pidLogsNumFeatures: raze listFromTableColumn[pidLogsTable;0]
gpsLogsFiles: raze listFromTableColumn[gpsLogsTable;1]
pidLogsFiles: raze listFromTableColumn[pidLogsTable;1]

/ create new master table if splayed table didn't load
/ add function to label each new log appended!
		/ if[not `GPSData in key`.; GPSData: enlistGPSCSV[first gpsLogsNumFeatures; first gpsLogsFiles];gpsLogsNumFeatures: 1_gpsLogsNumFeatures; gpsLogsFiles: 1_gpsLogsFiles] /use first log to initialise master table /drop first log already loaded
numGPSFiles:count gpsLogsFiles
GPSDataInput:enlistGPSCSV[first gpsLogsNumFeatures; first gpsLogsFiles]; gpsLogsNumFeatures: 1_gpsLogsNumFeatures; gpsLogsFiles: 1_gpsLogsFiles
if[numGPSFiles>1;{`GPSDataInput set GPSDataInput,enlistGPSCSV[(gpsLogsNumFeatures@x);(gpsLogsFiles@x)]} each til count gpsLogsNumFeatures]
/ :1

numPIDFiles:count pidLogsFiles
PIDDataInput: enlistPIDCSV[first pidLogsNumFeatures; first pidLogsFiles];pidLogsNumFeatures: 1_pidLogsNumFeatures; pidLogsFiles: 1_pidLogsFiles
if[numPIDFiles>1;{`PIDDataInput set PIDDataInput,enlistPIDCSV[(pidLogsNumFeatures@x);(pidLogsFiles@x)]} each til count pidLogsNumFeatures]
/ :1
/ adjust time data such that first time is 0us
/ if PID start time is earlier than GPS start time /writing "GPSDataInput[`timeus] 0" is the same as writing "first GPSDataInput[`timeus]"
if[res:(PIDDataInput[`timeus] 0)<(GPSDataInput[`timeus] 0); startTime:PIDDataInput[`timeus] 0] 
if[not res; startTime:GPSDataInput[`timeus] 0] /else statement
delete res from `. ; /delete res variable that is no longer needed

update timeus:timeus-startTime from `GPSDataInput;

delete startTime from `. ; /delete startTime variable that is no longer needed


/ convert us to ns
update timeus:1000*timeus from `GPSDataInput; /multiply us by 1000 /updates in place
GPSDataInput:`timeus xcols GPSDataInput /move timeus to front
GPSDataInput:`timens xcol GPSDataInput /rename timeus to timens

update timeus:1000*timeus from `PIDDataInput;
PIDDataInput:`timeus xcols PIDDataInput /move timeus to front
PIDDataInput:`timens xcol PIDDataInput /rename timeus to timens


/ switch to maximum precision for aj operation
/ \P 0 /disabled


/ cast from ns to timespan
update timens:`timespan$`long$timens from `GPSDataInput; /must cast to long first! /from long cast to timespan

update timens:`timespan$`long$timens from `PIDDataInput; 


/ key PIDDataInput and GPSDataInput tables with timens column
`timens xkey `PIDDataInput; 
`timens xkey `GPSDataInput;
/ join processed GPSDataInput with GPSData splayed table if it exists
if[`GPSData in key `.; `GPSData set GPSData,GPSDataInput]

/otherwise initialise GPSData table
if[not `GPSData in key`.; GPSData:GPSDataInput]
/ hsym `$flatDir,"GPSData" set GPSData; /save updated table
(hsym `$flatDir,"GPSData") set GPSData; /save updated table


/ join processed PIDDataInput with PIDDataInput splayed table if it exists
if[`PIDData in key`.; `PIDData set PIDData,PIDDataInput]
/otherwise initialise GPSData table
if[not `PIDData in key`.; PIDData:PIDDataInput]
(hsym `$flatDir,"PIDData") set PIDData; /save updated table

/ as of join the PID log and GPS log
fullLog:aj0[`timens;GPSData;PIDData];

(hsym `$flatDir,"fullLog") set fullLog; /save updated trainingData table

/ bucket into 1 tenths of a second
/ 1 xbar  raze each select timens from fullLog

/ create new log table trainingData of useful features only
trainingData: select timens,GPSspeedms,rcCommand0,rcCommand1,rcCommand2,rcCommand3,vbatLatestV,gyroADC0,gyroADC1,gyroADC2,accSmooth0,accSmooth1,accSmooth2,motor0,motor1,motor2,motor3 from fullLog where GPSspeedms>(minSpeedForFilter%3.6)


/ delete table(s) that is no longer required from default namespace `.
/ garbage collection not necessary???
/ https://stackoverflow.com/questions/34314997/how-to-delete-only-tables-in-kdb
/ ![`.;();0b;enlist `fullLog] /if only deleting fullLog (single table)
/ ![`.;();0b;enlist `fullLog]
/ ![`.;();0b;(`fullLog;`GPSData;`PIDData)]; /deletes tables fullLog, GPSData, PIDData


/ in trainingData table, convert timestamps from ns to us
update timens:`int$timens%1000 from `trainingData;
trainingData:`timeus xcol trainingData /rename timens to timeus

/ replace column GPSspeedms with GPSspeedkph
update GPSspeedkph:GPSspeedms*3.6 from `trainingData;
trainingData:`GPSspeedkph xcols trainingData; /place that new column in front
delete GPSspeedms from `trainingData;


/ create new column of sample time deltas
update timeDeltaus:`float$timeus[i+1]-timeus[i] from `trainingData; /must be float to allow conversion from table to matrix


/ DELETE ROW WITH MISSING DATA /DOUBLE CHECK THESE CONDITIONS
delete from `trainingData where rcCommand0 = 0n ; /delete rows where there are no rcCommands0 / these rows are not complete
delete from `trainingData where timeDeltaus = 0n; /delete rows where there are no timeDeltaus / these rows are not complete
delete from `trainingData where timeDeltaus <1; /delete rows where there are skips in time delta due to disjoined logs


/ create new column that show sample rate
update currentSampleHz:1%timeDeltaus%1000000 from `trainingData; 
trainingData:`currentSampleHz xcols trainingData; /place that new column in front
trainingData:`GPSspeedkph xcols trainingData; /place that new column in front
trainingData:`timeDeltaus xcols trainingData; /place that column in front
update timeus:`float$timeus from `trainingData;
/ `timeus xkey `trainingData; /do not key the table or it will become a dictionary! must be a table to convert to dictionary
(hsym `$flatDir,"trainingData") set trainingData; /save updated trainingData table

/ find out average sample rate
/ this query returns a table of single row
/ this single row is then flipped to dictionary (list) with single item
/ the 1st 'first' argument gets list from dictionary (read from right)
/ the 2nd 'first argument' (read from right) gets the first element/atom in the list
/ returns type of -9h to indicate it is a float atom
/ averageSampleFrequency:(string reciprocal[averageFreq:first averageFreq:(first averageFreq:flip select avg timeDeltaus from trainingData where timeDeltaus>0)%1000000]),"Hz"

/ delete unused variables using functional sql
varsToDelete: `gpsLogsFiles`gpsLogsNumFeatures`gpsLogsTable`isGPS`isPID`logsList`logsListTable`numFeaturesList`pidLogsFiles`pidLogsNumFeatures`pidLogsTable`GPSDataInput`PIDDataInput`minSpeedForFilter`numGPSFiles`numPIDFiles`varsToDelete
![`.;();0b;varsToDelete];

/ return back to working directory!
\cd /Users/foorx/Sites/OHR400Dashboard