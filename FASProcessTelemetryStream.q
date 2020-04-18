processTelemetryStreamBuffer:{
	telemetryStreamBufferDict:.j.k x;
	telemetryStreamBufferTable:enlist (`$string key telemetryStreamBufferDict)!value telemetryStreamBufferDict;
	fullLog::(keys fullLog)xkey(0!fullLog),telemetryStreamBufferTable;
	/ use select wanted features from buffer table
	show trainingDataNew:: select GPSspeedms,rcCommand0,rcCommand1,rcCommand2,rcCommand3,
		vbatLatestV,gyroADC0,gyroADC1,gyroADC2,accSmooth0,accSmooth1,accSmooth2,motor0,motor1,
		motor2,motor3 from telemetryStreamBufferTable;
	update GPSspeedkph: GPSspeedms*3.6 from `trainingDataNew;
	delete GPSspeedms from `trainingDataNew;
	update timeDeltaus:0.2f, currentSampleHz:5f,
		timeus:((last trainingData)[`timeus] + 200000) from `trainingDataNew;
	trainingData::trainingData,trainingDataNew;}