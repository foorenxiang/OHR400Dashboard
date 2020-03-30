/ \l telemetryStreamParser.q
demoInput:"{\" GPSnumSat\" :20,\" GPScoord0\" :1.329391,\" GPScoord1\" :103.7862,\" GPSaltitude\" :23,\" GPSspeedms\" :0.02,\" GPSgroundcourse\" :74.1,\" loopIteration\" :39976,\" axisP0\" :1,\" axisP1\" :2,\" axisP2\" :-26,\" axisI0\" :-33,\" axisI1\" :-13,\" axisI2\" :-57,\" axisD0\" :-1,\" axisD1\" :-4,\" axisD2\" :0,\" rcCommand0\" :-154,\" rcCommand1\" :-3,\" rcCommand2\" :29,\" rcCommand3\" :1423,\" vbatLatestV\" :1.586,\" rssi\" :1023,\" gyroADC0\" :-107,\" gyroADC1\" :-4,\" gyroADC2\" :25,\" accSmooth0\" :-2668,\" accSmooth1\" :14950,\" accSmooth2\" :672,\" motor0\" :700,\" motor1\" :1214,\" motor2\" :965,\" motor3\" :615,\" flightModeFlagsflags\" :null,\" stateFlagsflags\" :null,\" failsafePhaseflags\" :null,\" rxSignalReceived\" :1,\" rxFlightChannelsValid\" :1}"
telemetryStreamBuffer: .j.k demoInput
telemetryStreamBufferTable:enlist (`$string key telemetryStreamBuffer)!value telemetryStreamBuffer
/ telemetryStreamBufferTable:5#telemetryStreamBufferTable
trainingDataNew: select GPSspeedms,rcCommand0,rcCommand1,rcCommand2,rcCommand3,vbatLatestV,gyroADC0,gyroADC1,gyroADC2,accSmooth0,accSmooth1,accSmooth2,motor0,motor1,motor2,motor3 from telemetryStreamBufferTable
update GPSspeedkph: GPSspeedms%3.6 from `trainingDataNew
delete GPSspeedms from `trainingDataNew
update timeDeltaus:(count trainingDataNew)#0.2, currentSampleHz:(count trainingDataNew)#5f, timeus:((last trainingData)[`timeus] + 200000 *1 + til (count trainingDataNew)) from `trainingDataNew
trainingData,trainingDataNew
-8#trainingData