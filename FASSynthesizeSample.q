show "Generating timestep sample ",string 1+synthesizedSampleIndex
.p.set[`synthesizedSampleIndex; synthesizedSampleIndex]



/ extract current throttle sequences per timestep sample
/ used to generate/track B-Tree
existingThrottleHistory:raze flip select throttleInputHistory from LiPoPredictionTable
/ query a copy of LiPoPredictionTable without throttleInputSequence and synthesizedSampleIndex
/ delete is not applied to table in-place (delete query is a return value)
LiPoPredictionTimeShiftedTable: delete throttleInputSequence, synthesizedSampleIndex,
	throttleInputHistory from LiPoPredictionTable;
/ timeshift LiPoPredictionTable before feeding to ML model
update timeus:timeus+(syntheticSampleTimeDelta*1000000) from `LiPoPredictionTimeShiftedTable;
.p.set[`inputPDF; .ml.tab2df[LiPoPredictionTimeShiftedTable]]
/ \ts \l useGPRGPSModel.p / deploy Gaussian Process Regression GPS model
\ts \l useELMGPSModel.p / deply ELM regression model
newGPSPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF
/ do sample count matching
existingThrottleHistory:(neg count newGPSPredictionTable)#existingThrottleHistory
/ update throttleInputHistory
update throttleInputHistory:(existingThrottleHistory,'rcCommand3) from `newGPSPredictionTable;
/ join new predictions to existing predictions at end of table
gpsSpeedPredictionTable:gpsSpeedPredictionTable,newGPSPredictionTable
"Synthesize GPS speed"
\l delGPSDeployPythonObjects.q


/ extract current throttle sequences per timestep sample
/ used to generate/track B-Tree
existingThrottleHistory:raze flip select throttleInputHistory from gpsSpeedPredictionTable
/ query a copy of gpsSpeedPredictionTable without throttleInputSequence and synthesizedSampleIndex
/ delete is not applied to table in-place (delete query is a return value)
gpsSpeedPredictionTimeShiftedTable: delete throttleInputSequence, synthesizedSampleIndex,
	throttleInputHistory from gpsSpeedPredictionTable;
/ timeshift gpsSpeedPredictionTable before feeding to ML model
update timeus:timeus+(syntheticSampleTimeDelta*1000000) from
	`gpsSpeedPredictionTimeShiftedTable;
.p.set[`inputPDF; .ml.tab2df[gpsSpeedPredictionTimeShiftedTable]]
/ \ts \l useGPRLiPoModel.p / deploy Gaussian Process Regression LiPo Voltage model
\ts \l useELMLiPoModel.p / deploy ELM LiPo Voltage model
newLiPoPredictionTable:.ml.df2tab .p.wrap .p.pyget`LiPoPredictionPDF
/ do sample count matching
existingThrottleHistory:(neg count newLiPoPredictionTable)#existingThrottleHistory
/ update throttleInputHistory
update throttleInputHistory:(existingThrottleHistory,'rcCommand3)
	from `newLiPoPredictionTable;
/ join new predictions to existing predictions at end of table
LiPoPredictionTable:LiPoPredictionTable,newLiPoPredictionTable
"Synthesize voltage"
\l delLiPoDeployPythonObjects.q


/ increment synthesized sample index
synthesizedSampleIndex+:1
/ display number of samples at each stage in q console
show synthesizedDataCount: synthesizedDataCount,getSynthesizedDataCount[]