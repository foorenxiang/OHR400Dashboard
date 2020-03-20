//////split dataset into training and test data//////
trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);testPercentage:0.2]
testingSamples:(til count dataset) except (trainingSamples:where dataset:trainTestSplitTrainingData[`ytrain]=1b)
`testingSamples`trainingSamples!(testingSamples;trainingSamples);

/ give python access to training data panda dataframe
.p.set[`trainingDataPDF; .ml.tab2df[trainTestSplitTrainingData[`xtrain]]]

//////TRAIN GPS PREDICTION MODEL//////
/ train gps speed prediction model
"Training GPS speed prediction model"
/ \l updateLinearGPSModel.p / train linear regression model
/ \l updateSVRGPSModel.p / train support vector regression model
/ \l updateAdaboostGPSModel.p / train adaboost model
/ \l updateELMGPSModel.p / train Extreme Learning Machine model
/ \l updateGPRGPSModel.p / train gaussian process regression model

//////TRAIN LIPO PREDICTION MODEL//////
"Training LiPo Voltage prediction model"
.p.set[`trainingDataPDF; .ml.tab2df[trainTestSplitTrainingData[`xtrain]]]
/ \l updateGPRLiPoModel.p / train gaussian process regression model
/ \l updateELMLiPoModel.p / train ELM model

/ number of look ahead samples for training LSTM
numSamplesToUse:10
.p.set[`numSamplesToUse; numSamplesToUse]
numSamplesToUse:(neg(numSamplesToUse)) / take samples from end of table
synthesizedSampleIndex:0
.p.set[`synthesizedSampleIndex; synthesizedSampleIndex]
//////DEPLOY GPS MODEL//////
"Deploying GPS speed prediction model"
/ give python access to testing data panda dataframe
/ always call .p.set to ensure model receives fresh panda dataframe
/ .p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]] / use this input to test the model
.p.set[`inputPDF; .ml.tab2df[numSamplesToUse#trainingData]]
/ \ts \l useGPRGPSModel.p / deploy gaussian process regression model
\ts \l useELMGPSModel.p / deploy ELM model
/ \ts \l useLinearGPSModel.p / deploy linear model
/ convert prediction result from python object back to q list
gpsSpeedPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF	

//////DEPLOY LIPO MODEL//////
"Deploying LiPo Voltage prediction model"
/ give python access to testing data panda dataframe
/ always call .p.set to ensure model receives fresh panda dataframe
synthesizedSampleIndex:1
.p.set[`synthesizedSampleIndex; synthesizedSampleIndex]
.p.set[`inputPDF; .ml.tab2df[numSamplesToUse#trainingData]]
/ \ts \l useGPRLiPoModel.p / deploy gaussian process regression model
\ts \l useELMLiPoModel.p / deploy ELM model
/ convert prediction result from python object back to q list
LiPoPredictionTable:.ml.df2tab .p.wrap .p.pyget`LiPoPredictionPDF

//////VERIFY GPS MODEL//////
/
.p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]] / use this input to test the model
\ts \l useLinearGPSModel.p / deploy linear model
\ts \l useGPRGPSModel.p / deploy gaussian process regression model
/ / convert prediction result from python object back to q list
gpsSpeedPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF
\

//////VERIFY LIPO MODEL//////
/
/ always call .p.set to ensure model receives fresh panda dataframe
.p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]] / use this input to test the model
.p.set[`inputPDF; .ml.tab2df[numSamplesToUse#trainingData]]
\ts \l useGPRLiPoModel.p / deploy gaussian process regression model
/ convert prediction result from python object back to q list
LiPoPredictionTable:.ml.df2tab .p.wrap .p.pyget`LiPoPredictionPDF
\

//////Synthesize time series data from traing LSTM network//////
lowThrottle:1000
highThrottle:2000
throttleSteps:10 / resolution of throttle variations
.p.set[`lowThrottle; lowThrottle]
.p.set[`highThrottle; highThrottle]
.p.set[`throttleSteps; throttleSteps]
"Parameters for data synthesis:"
"lowThrottle"
show lowThrottle
"highThrottle"
show highThrottle
"throttleSteps"
show throttleSteps

"Synthesizing GPS speeds and LiPo voltage for different throttle values and timesteps"
/ note that 1 timestep is already created at this point
/ numTimeSteps indicate how many ADDITIONAL timesteps to synthesize
numTimeSteps:20
getSynthesizedDataCount:{flip `Sample`gpsSpeedPredictionTableRowCount`LiPoPredictionTableRowCount!enlist each (synthesizedSampleIndex-1),count each (gpsSpeedPredictionTable;LiPoPredictionTable)}
synthesizedDataCount: getSynthesizedDataCount[]
{system "l FASSynthesizeSample.q"} each til numTimeSteps;

/ EACH TIMESTEP SHOULD CONSIDER BOTH SPEED AND VOLTAGE PREDICTIONS. I.E DROP VOLTAGE FEATURE FROM GPS PREDICTION DF AND VICE VERSA, THEN JOIN THE TWO PREDICTION TABLES TOGETHER

/ clean up synthesized sample index in tables
/ CONSIDER IF DELETE OF COLUMN SHOULD BE DONE IN FASSynthesizeSample.q
update synthesizedSampleIndex:first each synthesizedSampleIndex from `LiPoPredictionTable;
delete GPSspeedkph from `LiPoPredictionTable;
update synthesizedSampleIndex:first each synthesizedSampleIndex from `gpsSpeedPredictionTable;
delete vbatLatestV from `gpsSpeedPredictionTable;

/ cols LiPoPredictionTable
/ `timeDeltaus`timeus`rcCommand3`GPSspeedkph`currentSampleHz`rcCommand0`rcCommand1`rcCommand2`gyroADC0`gyroADC1`gyroADC2`accSmooth0`accSmooth1`accSmooth2`motor0`motor1`motor2`motor3`vbatLatestV`throttleInputSequence`synthesizedSampleIndex
/ cols gpsSpeedPredictionTable
/ `timeDeltaus`timeus`rcCommand3`currentSampleHz`rcCommand0`rcCommand1`rcCommand2`vbatLatestV`gyroADC0`gyroADC1`gyroADC2`accSmooth0`accSmooth1`accSmooth2`motor0`motor1`motor2`motor3`GPSspeedkph`throttleInputSequence`synthesizedSampleIndex

/ key each table in preparation for inner join
keyTableFeatures: `synthesizedSampleIndex`throttleInputSequence`timeus`rcCommand3`timeDeltaus / `vbatLatestV`gyroADC0`gyroADC1`gyroADC2`accSmooth0`accSmooth1`accSmooth2`motor0`motor1`motor2`motor3`GPSspeedkph`throttleInputSequence`synthesizedSampleIndex
keyTableFeatures xkey `gpsSpeedPredictionTable;
keyTableFeatures xkey `LiPoPredictionTable;
fullPredictionTable:LiPoPredictionTable ij gpsSpeedPredictionTable;
0!`fullPredictionTable; / unkey new table after join
/save updated fullPredictionTable table
(hsym `$flatDir,"fullPredictionTable") set fullPredictionTable; / use hsym t cast directory string to file symbol

/ cols each `gpsSpeedPredictionTable`LiPoPredictionTable`fullPredictionTable
/ table columns with GPR model
/ gpsSpeedPredictionTable:
/ `timeDeltaus`timeus`rcCommand3`synthesizedSampleIndex`currentSampleHz`rcCommand0`rcCommand1`rcCommand2`gyroADC0`gyroADC1`gyroADC2`accSmooth0`accSmooth1`accSmooth2`motor0`motor1`motor2`motor3`GPSspeedkph`throttleInputSequence
/ LiPoPredictionTable
/ `timeDeltaus`timeus`rcCommand3`synthesizedSampleIndex`currentSampleHz`rcCommand0`rcCommand1`rcCommand2`gyroADC0`gyroADC1`gyroADC2`accSmooth0`accSmooth1`accSmooth2`motor0`motor1`motor2`motor3`vbatLatestV`throttleInputSequence
/ fullPredictionTable
/ `timeDeltaus`timeus`rcCommand3`synthesizedSampleIndex`currentSampleHz`rcCommand0`rcCommand1`rcCommand2`gyroADC0`gyroADC1`gyroADC2`accSmooth0`accSmooth1`accSmooth2`motor0`motor1`motor2`motor3`vbatLatestV`throttleInputSequence`GPSspeedkph

show "Completed Updating Models"

//////Synthesize time series data from traing LSTM network//////
/ to be implemented

//////SANDBOX AREA//////
/ -1 "SANDBOX AREA ACTIVE"
/ (cols delete throttleInputSequence from trainTestSplitTrainingData[`xtrain]) except (cols LiPoPredictionTable)
/ (cols delete throttleInputSequence from LiPoPredictionTable) except (cols trainTestSplitTrainingData[`xtrain])
/ (cols ([] col1:`a`b; col2:1 2)) except cols ([] col3:`a`b; col4:1 2)