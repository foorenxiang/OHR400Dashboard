\cd /Users/foorx/logs
//read CSV containing files just uploaded to logs folder
logsListTable: ("I*";enlist csv) 0: `:logsManifest.csv
//remove non-valid rows
logsListTable: select from logsListTable where numColumns <> 0N
//select only files column from logsListTable and assign to logsList as list
logsList: `$listFromTableColumn[logsListTable;1]
numFeaturesList: raze listFromTableColumn[logsListTable;0]
/delete logsListTable from `.



//write function that determines if it is a GPS or PID csv!!
isGPS: (0 ^ first each ss[;"?gps"] each string each logsList) > 0
isPID: (0 ^ first each ss[;"?01.csv"] each string each logsList) > 0
logsListTable:([]numFeatures: numFeaturesList; Files:logsList;isGPS:isGPS; isPID:isPID) /update logsListTable

gpsLogsTable: select numFeatures,Files from logsListTable where isGPS = 1
pidLogsTable: select numFeatures,Files from logsListTable where isPID = 1
gpsLogsNumFeatures: raze listFromTableColumn[gpsLogsTable;0]
pidLogsNumFeatures: raze listFromTableColumn[pidLogsTable;0]
gpsLogsFiles: raze listFromTableColumn[gpsLogsTable;1]
pidLogsFiles: raze listFromTableColumn[pidLogsTable;1]

/create new master table if splayed table didn't load
/add function to label each new log appended!
if[not `GPSData in key`.; GPSData: enlistGPSCSV[first gpsLogsNumFeatures; first gpsLogsFiles];gpsLogsNumFeatures: 1_gpsLogsNumFeatures; gpsLogsFiles: 1_gpsLogsFiles] /use first log to initialise master table /drop first log already loaded
{`GPSData set GPSData,enlistGPSCSV[(gpsLogsNumFeatures@x);(gpsLogsFiles@x)]} each til count gpsLogsNumFeatures
`:/Users/foorx/Sites/OHR400Dashboard/GPSData set GPSData; /save updated table


if[not `PIDData in key`.; PIDData: enlistPIDCSV[first pidLogsNumFeatures; first pidLogsFiles]; pidLogsNumFeatures: 1_pidLogsNumFeatures; pidLogsFiles: 1_pidLogsFiles] /use first log to initialise master table /drop first log already loaded
{`PIDData set PIDData,enlistPIDCSV[(pidLogsNumFeatures@x);(pidLogsFiles@x)]} each til count pidLogsNumFeatures;
`:/Users/foorx/Sites/OHR400Dashboard/PIDData set PIDData; /save updated table

/
//DO NOT USE THIS FUNCTION AS IT WILL RESET logsManifest.csv PERMISSIONS! WILL CAUSE PHP SCRIPT TO STOP WORKING
//erase logsList to prep for next upload cycle
logsManifest:([]dummyColumn:(); Files:())
save `logsManifest.csv
\

/ \cd /Users/foorx

/GPSData: ("f",(7-1)#"f";enlist csv) 0: `$directory,logName,"_GPS.csv"
/ \ts PIDData: ("ff",(32-2)#"f";enlist csv) 0: `$directory,logName,"_PID.csv"

/ directory: "tensorflow/"
/ logName: "train_020319_LOG00049_56_58_59"

/ \ts GPSData: ("f",(7-1)#"f";enlist csv) 0: `$directory,logName,"_GPS.csv"
/ \ts PIDData: ("ff",(32-2)#"f";enlist csv) 0: `$directory,logName,"_PID.csv"
/load data
/ "time (ms) & space (bytes) taken to load CSVs"
/ GPSData: ("f",(7-1)#"f";enlist csv) 0: `:tensorflow/train_020319_LOG00049_56_58_59_GPS.csv
/ PIDData: ("ff",(32-2)#"f";enlist csv) 0: `:tensorflow/train_020319_LOG00049_56_58_59_PID.csv

/trim data
/ `GPSData set trimTable[GPSData];
/ `PIDData set trimTable[PIDData];

/adjust time data such that first time is 0us
if[res:(PIDData[`timeus] 0)<(GPSData[`timeus] 0); startTime:PIDData[`timeus] 0] /if PID start time is earlier than GPS start time /writing "GPSData[`timeus] 0" is the same as writing "first GPSData[`timeus]"
if[not res; startTime:GPSData[`timeus] 0] /else statement
delete res from `. ; /delete res variable that is no longer needed

update timeus:timeus-startTime from `GPSData;

update timeus:timeus-startTime from `PIDData;

delete startTime from `. ; /delete startTime variable that is no longer needed


/convert us to ns
update timeus:1000*timeus from `GPSData; /multiply us by 1000 /updates in place
GPSData:`timeus xcols GPSData /move timeus to front
GPSData:`timens xcol GPSData /rename timeus to timens

update timeus:1000*timeus from `PIDData;
PIDData:`timeus xcols PIDData /move timeus to front
PIDData:`timens xcol PIDData /rename timeus to timens


/switch to maximum precision for aj operation
/ \P 0 /disabled


/cast from ns to timespan
update timens:`timespan$`long$timens from `GPSData; /must cast to long first! /from long cast to timespan

update timens:`timespan$`long$timens from `PIDData; 


/key PIDData and GPSData tables with timens column
`timens xkey `PIDData; 
`timens xkey `GPSData;

/as of join the PID log and GPS log
fullLog:aj0[`timens;GPSData;PIDData];

`:/Users/foorx/Sites/OHR400Dashboard/fullLog set fullLog; /save updated trainingData table

/bucket into 1 tenths of a second
/ 1 xbar  raze each select timens from fullLog

minSpeedForFilter: 100 /in kph
/create new log table trainingData of useful features only
trainingData: select timens,GPSspeedms,rcCommand0,rcCommand1,rcCommand2,rcCommand3,vbatLatestV,gyroADC0,gyroADC1,gyroADC2,accSmooth0,accSmooth1,accSmooth2,motor0,motor1,motor2,motor3 from fullLog where GPSspeedms>(minSpeedForFilter%3.6)


/delete table(s) that is no longer required from default namespace `.
/garbage collection not necessary???
/ https://stackoverflow.com/questions/34314997/how-to-delete-only-tables-in-kdb
/![`.;();0b;enlist `fullLog] /if only deleting fullLog (single table)
/![`.;();0b;enlist `fullLog]
/![`.;();0b;(`fullLog;`GPSData;`PIDData)]; /deletes tables fullLog, GPSData, PIDData

/replace column GPSspeedms with GPSspeedkph
update GPSspeedkph:GPSspeedms*3.6 from `trainingData;
trainingData:`GPSspeedkph xcols trainingData; /place that new column in front
delete GPSspeedms from `trainingData;


/in trainingData table, convert timestamps from ns to us
update timens:`int$timens%1000 from `trainingData;
trainingData:`timeus xcol trainingData /rename timeus to timens


/create new column of sample time deltas
update timeDeltaus:`float$timeus[i+1]-timeus[i] from `trainingData; /must be float to allow conversion from table to matrix


/DELETE ROW WITH MISSING DATA /DOUBLE CHECK THESE CONDITIONS
delete from `trainingData where rcCommand0 = 0n ; /delete rows where there are no rcCommands0 / these rows are not complete
delete from `trainingData where timeDeltaus = 0n; /delete rows where there are no timeDeltaus / these rows are not complete
delete from `trainingData where timeDeltaus <1; /delete rows where there are skips in time delta due to disjoined logs


/create new column that show sample rate
update currentSampleHz:1%timeDeltaus%1000000 from `trainingData; 
trainingData:`currentSampleHz xcols trainingData; /place that new column in front
trainingData:`GPSspeedkph xcols trainingData; /place that new column in front
trainingData:`timeDeltaus xcols trainingData; /place that column in front
update timeus:`float$timeus from `trainingData;
/`timeus xkey `trainingData; /do not key the table or it will become a dictionary! must be a table to convert to dictionary
`:/Users/foorx/Sites/OHR400Dashboard/trainingData set trainingData; /save updated trainingData table

/find out average sample rate
/this query returns a table of single row
/this single row is then flipped to dictionary (list) with single item
/the 1st 'first' argument gets list from dictionary (read from right)
/the 2nd 'first argument' (read from right) gets the first element/atom in the list
/returns type of -9h to indicate it is a float atom
averageSampleFrequency:(string reciprocal[averageFreq:first averageFreq:(first averageFreq:flip select avg timeDeltaus from trainingData where timeDeltaus>0)%1000000]),"Hz"
/ delete averageSampleFrequency from `.;


/get basic stats description of trainingData
show trainingDataDescription:.ml.describe[trainingData]

/calculate covariance matrix of trainingData
/ "covariance matrix of trainingData"
covarianceMatrix:.ml.cvm[flip value flip trainingData] /"flip value flip" performed to strip the vectors from the table
covarianceVector:raze covarianceMatrix
covarianceTable: ([] featurePair:idesc covarianceVector; covarianceValue: desc covarianceVector) /sort by decreasing covariance
selectedNumComponents: 50
selectedPCTable: select[selectedNumComponents] from covarianceTable
covarianceExplanationPercentage: first raze/[(select[selectedNumComponents] covarianceValue from covarianceTable) % sum(covarianceVector)]


//DOUBLE CHECK WHAT THESE FUNCTIONS ARE RETURNING!
iterateNumComponents:{[selectedNumComponents] covarianceExplanationPercentage: first raze/[(select[selectedNumComponents] covarianceValue from covarianceTable) % sum(covarianceVector)]} 
maxComponents: `int$sqrt[1721344]
componentNumVector: 200*1+til 50
componentNumVector: 1+ til maxComponents
resultsFromComponentsVector:iterateNumComponents each componentNumVector
resultsFromComponentsTable:([] numOfComponents: componentNumVector[idesc resultsFromComponentsVector]; covarianceValue: desc resultsFromComponentsVector)


/calculate covariance matrix permutations
covarianceMatrixPermutations: pn[count cols trainingData;count cols trainingData]


/housekeeping functions
varsToDelete: `PIDNumFeatures`gpsLogsFiles`gpsLogsNumFeatures`gpsLogsTable`gpsNumFeatures`isGPS`isPID`logsList`logsListTable`numFeaturesList`pidLogsFiles`pidLogsNumFeatures`pidLogsTable`trainingDataDescription`varsToDelete
![`.;();0b;varsToDelete]; / delete unneeded variables using functional sql 
\cd /Users/foorx/Sites/OHR400Dashboard