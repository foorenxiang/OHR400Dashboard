minSpeed:170
visualisationTable: select timens,lat:GPScoord0,long:GPScoord1,GPSspeedms,rcCommand0,rcCommand1,rcCommand2,rcCommand3,vbatLatestV,gyroADC0,gyroADC1,gyroADC2,accSmooth0,accSmooth1,accSmooth2,motor0,motor1,motor2,motor3 from fullLog where GPSspeedms>(minSpeed%3.6)
/ in visualisationTable table, convert timestamps from ns to us
update timens:`int$timens%1000 from `visualisationTable;
/rename timens to timeus
visualisationTable:`timeus xcol visualisationTable 

/ replace column GPSspeedms with GPSspeedkph
update GPSspeedkph:GPSspeedms*3.6 from `visualisationTable;
/place that new column in front
visualisationTable:`GPSspeedkph xcols visualisationTable;
delete GPSspeedms from `visualisationTable;

/ create new column of sample time deltas
update timeDeltaus:`float$timeus[i+1]-timeus[i] from `visualisationTable; /must be float to allow conversion from table to matrix

/ delete timestamp and rely on time delta instead
/ delete timens from `visualisationTable;

/ removes samples with missing features in dataset
delete from `visualisationTable where rcCommand0 = 0n ; /delete rows where there are no rcCommands0
delete from `visualisationTable where timeDeltaus = 0n; /delete rows where there are no timeDeltaus
delete from `visualisationTable where timeDeltaus <0; /delete rows where there are skips in time delta due to log transition
/ create new column that show sample rate
update currentSampleHz:1%timeDeltaus%1000000 from `visualisationTable; 
delete from `visualisationTable where currentSampleHz>30;
delete from `visualisationTable where currentSampleHz<2;
/ reorder columns
visualisationTable:`currentSampleHz xcols visualisationTable;
visualisationTable:`GPSspeedkph xcols visualisationTable;
visualisationTable:`timeDeltaus xcols visualisationTable;
update timeus:`float$timeus from `visualisationTable;