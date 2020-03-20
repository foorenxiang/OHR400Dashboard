show "Generating timestep sample ",string 1+synthesizedSampleIndex
.p.set[`synthesizedSampleIndex; synthesizedSampleIndex]
.p.set[`inputPDF; .ml.tab2df[delete throttleInputSequence, synthesizedSampleIndex from LiPoPredictionTable]]
/ \ts \l useGPRGPSModel.p / deploy gaussian process regression model
\ts \l useELMGPSModel.p
gpsSpeedPredictionTable:gpsSpeedPredictionTable,.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF

/
/ CONTINUE WORKING ON HOW TO MAKE GPS AND LIPO SAMPLES NOT OVERLAP EACH OTHER??
/ OR SHOULD THEY COMPLIMENT EACH OTHER I.E. CHOOSE THE RIGHT COLUMNS TO OVERWRITE PER PREDICTION STEP 
synthesizedSampleIndex+:1
show "Generating timestep sample ",string 1+synthesizedSampleIndex
.p.set[`synthesizedSampleIndex; synthesizedSampleIndex]
\

.p.set[`inputPDF; .ml.tab2df[delete throttleInputSequence, synthesizedSampleIndex from gpsSpeedPredictionTable]]
/ \ts \l useGPRLiPoModel.p / deploy gaussian process regression model
\ts \l useELMLiPoModel.p / deploy ELM model
LiPoPredictionTable:LiPoPredictionTable,.ml.df2tab .p.wrap .p.pyget`LiPoPredictionPDF

show synthesizedDataCount: synthesizedDataCount,getSynthesizedDataCount[]