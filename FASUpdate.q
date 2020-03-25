/ get directories
qDirectory: get `:qDirectory
dashboardDirectory: get `:dashboardDirectory
logsDirectory: get `:logsDirectory

///////////////////////
/ Filter parameters
minSpeed: 60 /in kph
///////////////////////

system"cd ",logsDirectory

/ read CSV containing files just uploaded to logs folder
logsListTable: ("I*";enlist csv) 0: `:logsManifest.csv
/ remove non-valid rows
logsListTable: select from logsListTable where numColumns <> 0N
/ select only files column from logsListTable and assign to logsList as list
logsList: `$listFromTableColumn[logsListTable;1]
/ get feature count for each log
numFeaturesList: raze listFromTableColumn[logsListTable;0]

/ create list indicating if log file is a gps log
isGPS: (0 ^ first each ss[;"?gps"] each string each logsList) > 0
/ create list indicating if log file is a pid log
isPID: (0 ^ first each ss[;"?01.csv"] each string each logsList) > 0
/ tabulate logs, # features in each log , if log is gps, if log is pid
logsListTable:([]numFeatures: numFeaturesList; Files:logsList;isGPS:isGPS; isPID:isPID) /create logsListTable

gpsLogsTable: select numFeatures,Files from logsListTable where isGPS = 1
pidLogsTable: select numFeatures,Files from logsListTable where isPID = 1

/ listFromTableColumn function is defined in FASInit.q
gpsLogsNumFeatures: raze listFromTableColumn[gpsLogsTable;0]
pidLogsNumFeatures: raze listFromTableColumn[pidLogsTable;0]
gpsLogsFiles: raze listFromTableColumn[gpsLogsTable;1]
pidLogsFiles: raze listFromTableColumn[pidLogsTable;1]

/ create new master table if splayed table didn't load
// add function to label each new log appended!
/ if[not `GPSData in key`.; GPSData: enlistGPSCSV[first gpsLogsNumFeatures; first gpsLogsFiles];gpsLogsNumFeatures: 1_gpsLogsNumFeatures; gpsLogsFiles: 1_gpsLogsFiles] /use first log to initialise master table /drop first log already loaded

/ build input from gps log files
numGPSFiles:count gpsLogsFiles
/ read first gps log file
GPSDataInput:enlistGPSCSV[first gpsLogsNumFeatures; first gpsLogsFiles]; gpsLogsNumFeatures: 1_gpsLogsNumFeatures; gpsLogsFiles: 1_gpsLogsFiles
/ if multiple pid log files are present, read the rest
if[numGPSFiles>1;{`GPSDataInput set GPSDataInput,enlistGPSCSV[(gpsLogsNumFeatures@x);(gpsLogsFiles@x)]} each til count gpsLogsNumFeatures]

/ build input from pid log files
numPIDFiles:count pidLogsFiles
/ read first pid log file
PIDDataInput: enlistPIDCSV[first pidLogsNumFeatures; first pidLogsFiles];pidLogsNumFeatures: 1_pidLogsNumFeatures; pidLogsFiles: 1_pidLogsFiles
if[numPIDFiles>1;{`PIDDataInput set PIDDataInput,enlistPIDCSV[(pidLogsNumFeatures@x);(pidLogsFiles@x)]} each til count pidLogsNumFeatures]

/ adjust time data such that first entry starts at 0us
/ if PID start time is earlier than GPS start time 
if[res:(PIDDataInput[`timeus] 0)<(GPSDataInput[`timeus] 0); startTime:PIDDataInput[`timeus] 0] 
if[not res; startTime:GPSDataInput[`timeus] 0]
delete res from `. ;

update timeus:timeus-startTime from `GPSDataInput;
delete startTime from `. ;

/ convert us to ns
update timeus:1000*timeus from `GPSDataInput; /multiply us by 1000 /updates in place
GPSDataInput:`timeus xcols GPSDataInput /move timeus to front
GPSDataInput:`timens xcol GPSDataInput /rename timeus to timens

update timeus:1000*timeus from `PIDDataInput;
PIDDataInput:`timeus xcols PIDDataInput /move timeus to front
PIDDataInput:`timens xcol PIDDataInput /rename timeus to timens

/ cast from ns to timespan
/must cast to long first! /from long cast to timespan
update timens:`timespan$`long$timens from `GPSDataInput; 
update timens:`timespan$`long$timens from `PIDDataInput; 

/ key PIDDataInput and GPSDataInput tables with timens column
`timens xkey `PIDDataInput; 
`timens xkey `GPSDataInput;
/ join processed GPSDataInput with GPSData splayed table if it exists
if[`GPSData in key `.; `GPSData set GPSData,GPSDataInput]
/otherwise initialise GPSData table
if[not `GPSData in key`.; GPSData:GPSDataInput]
/save updated table
(hsym `$flatDir,"GPSData") set GPSData; / use hsym t cast directory string to file symbol
if[saveCSVs;save `:GPSData.csv;show "GPSData.csv saved to disk"]

/ join processed PIDDataInput with PIDDataInput splayed table if it exists
if[`PIDData in key`.; `PIDData set PIDData,PIDDataInput]
/otherwise initialise GPSData table
if[not `PIDData in key`.; PIDData:PIDDataInput]
/save updated table
(hsym `$flatDir,"PIDData") set PIDData; / use hsym t cast directory string to file symbol
if[saveCSVs;save `:PIDData.csv;show "PIDData.csv saved to disk"]

/ as of join the PID log and GPS log
fullLog:aj0[`timens;GPSData;PIDData];
/save updated trainingData table
(hsym `$flatDir,"fullLog") set fullLog; / use hsym t cast directory string to file symbol
if[saveCSVs;save `:fullLog.csv;show "fullLog.csv saved to disk"]
/ bucket into 1 tenths of a second
/ 1 xbar raze each select timens from fullLog

/ feature selection for trainingData
trainingData: select timens,GPSspeedms,rcCommand0,rcCommand1,rcCommand2,rcCommand3,vbatLatestV,gyroADC0,gyroADC1,gyroADC2,accSmooth0,accSmooth1,accSmooth2,motor0,motor1,motor2,motor3 from fullLog where GPSspeedms>(minSpeed%3.6)

/ copy trainingData table with renamed features
trainingData1:(`rcCommand0`rcCommand1`rcCommand2`rcCommand3!`rcRoll`rcPitch`rcYaw`rcThrottle)xcol trainingData

/ in trainingData table, convert timestamps from ns to us
update timens:`int$timens%1000 from `trainingData;
/rename timens to timeus
trainingData:`timeus xcol trainingData 

/ replace column GPSspeedms with GPSspeedkph
update GPSspeedkph:GPSspeedms*3.6 from `trainingData;
/place that new column in front
trainingData:`GPSspeedkph xcols trainingData;
delete GPSspeedms from `trainingData;

/ create new column of sample time deltas
update timeDeltaus:`float$timeus[i+1]-timeus[i] from `trainingData; /must be float to allow conversion from table to matrix

/ removes samples with missing features in dataset
delete from `trainingData where rcCommand0 = 0n ; /delete rows where there are no rcCommands0
delete from `trainingData where timeDeltaus = 0n; /delete rows where there are no timeDeltaus
delete from `trainingData where timeDeltaus <1; /delete rows where there are skips in time delta due to log transition

/ create new column that show sample rate
update currentSampleHz:1%timeDeltaus%1000000 from `trainingData; 
/ reorder columns
trainingData:`currentSampleHz xcols trainingData;
trainingData:`GPSspeedkph xcols trainingData;
trainingData:`timeDeltaus xcols trainingData;
update timeus:`float$timeus from `trainingData;
/do not key the table or it will become a dictionary! must be a table to convert to dictionary
/ `timeus xkey `trainingData; 
(hsym `$flatDir,"trainingData") set trainingData; /save updated trainingData table
if[saveCSVs;save `:trainingData.csv;show "trainingData.csv saved to disk"]

/ find out average sample rate
/ this query returns a table of single row
/ this single row is then flipped to dictionary (list) with single item
/ the 1st 'first' argument gets list from dictionary (read from right)
/ the 2nd 'first argument' (read from right) gets the first element/atom in the list
/ returns type of -9h to indicate it is a float atom
/ averageSampleFrequency:(string reciprocal[averageFreq:first averageFreq:(first averageFreq:flip select avg timeDeltaus from trainingData where timeDeltaus>0)%1000000]),"Hz"

/ clean up unused variables using functional sql
varsToDelete: `gpsLogsFiles`gpsLogsNumFeatures`gpsLogsTable`isGPS`isPID`logsList`logsListTable`numFeaturesList`pidLogsFiles`pidLogsNumFeatures`pidLogsTable`GPSDataInput`PIDDataInput`minSpeed`numGPSFiles`numPIDFiles`varsToDelete
![`.;();0b;varsToDelete];

/ return back to working directory!
system"cd ",dashboardDirectory