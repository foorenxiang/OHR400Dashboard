show "Generating timestep sample ",string 1+synthesizedSampleIndex
.p.set[`synthesizedSampleIndex; synthesizedSampleIndex]
.p.set[`inputPDF; .ml.tab2df[delete throttleInputSequence, synthesizedSampleIndex from LiPoPredictionTable]]
/ \ts \l useGPRGPSModel.p / deploy gaussian process regression model
\ts \l useELMGPSModel.p
gpsSpeedPredictionTable:gpsSpeedPredictionTable,.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF

.p.set[`inputPDF; .ml.tab2df[delete throttleInputSequence, synthesizedSampleIndex from gpsSpeedPredictionTable]]
/ \ts \l useGPRLiPoModel.p / deploy gaussian process regression model
\ts \l useELMLiPoModel.p / deploy ELM model
LiPoPredictionTable:LiPoPredictionTable,.ml.df2tab .p.wrap .p.pyget`LiPoPredictionPDF

synthesizedSampleIndex+:1
show synthesizedDataCount: synthesizedDataCount,getSynthesizedDataCount[]