useTrainTestSplit:0b

//////split dataset into training and test data//////
trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);testPercentage:0]
testingSamples:(til count dataset) except (trainingSamples:where dataset:trainTestSplitTrainingData[`ytrain]=1b)
trainTestSplitAssignmentTable:`testingSamples`trainingSamples!(testingSamples;trainingSamples);
/ give python access to training data panda dataframe
if[useTrainTestSplit;.p.set[`trainingDataPDF; .ml.tab2df[trainTestSplitTrainingData[`xtrain]]];show "Using train test split!"]
if[not useTrainTestSplit;.p.set[`trainingDataPDF; .ml.tab2df[trainingData]];show "Not using train test split!"]


//////TRAIN GPS PREDICTION MODEL//////
"Training GPS speed prediction model"
\l updateELMGPSModel.p / train Extreme Learning Machine model
/ \l updateGPRGPSModel.p / train gaussian process regression model
/ \l updateLinearGPSModel.p / train linear regression model
/ \l updateSVRGPSModel.p / train support vector regression model
/ \l updateAdaboostGPSModel.p / train adaboost model
/ \l updateGradboostGPSModel.p / train Gradient Boost model
/ \l updateXGBoostGPSModel.p / train XGBoost model
/ \l updateRFGPSModel.p / train adaboost model (To be implemented)
/ \l updateStackGeneralizerGPSModel.p / train Stack Generalizer model (To be implemented)

//////TRAIN LIPO PREDICTION MODEL//////
"Training LiPo Voltage prediction model"
.p.set[`trainingDataPDF; .ml.tab2df[trainingData]]
\l updateELMLiPoModel.p / train ELM model
/ \l updateGPRLiPoModel.p / train gaussian process regression model
/ \l updateSVRLiPoModel.p / train support vector regression model (To be implemented)
/ \l updateAdaboostLiPoModel.p / train adaboost model (To be implemented)
/ \l updateGradboostLiPoModel.p / train Gradient Boost model (To be implemented)
/ \l updateXGBoostLiPoModel.p / train XGBoost model (To be implemented)
/ \l updateRFLiPoModel.p / train adaboost model (To be implemented)
/ \l updateStackGeneralizerLiPoModel.p / train Stack Generalizer model (To be implemented)

/ number of look ahead samples for training LSTM
.p.set[`numSamplesToUse; numSamplesToUse:10]
.p.set[`synthesizedSampleIndex; synthesizedSampleIndex:0]
//////DEPLOY GPS MODEL//////
"Deploying GPS speed prediction model"
/ give python access to testing data panda dataframe
/ always call .p.set to ensure model receives fresh panda dataframe
/ .p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]] / use this input to test the model
.p.set[`inputPDF; .ml.tab2df[(neg numSamplesToUse)#trainingData]] / take samples from end of table
/ \ts \l useGPRGPSModel.p / deploy gaussian process regression model
\ts \l useELMGPSModel.p / deploy ELM model
/ \ts \l useLinearGPSModel.p / deploy linear model
/ \l useSVRGPSModel.p / train support vector regression model (To be implemented)
/ \l useAdaboostGPSModel.p / train adaboost model (To be implemented)
/ \l useGradboostGPSModel.p / train Gradient Boost model (To be implemented)
/ \l useXGBoostGPSModel.p / train XGBoost model (To be implemented)
/ \l useRFGPSModel.p / train adaboost model (To be implemented)
/ \l useStackGeneralizerGPSModel.p / train Stack Generalizer model (To be implemented)
/ convert prediction result from python object back to q list
gpsSpeedPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF	

//////DEPLOY LIPO MODEL//////
"Deploying LiPo Voltage prediction model"
/ give python access to testing data panda dataframe
/ always call .p.set to ensure model receives fresh panda dataframe
synthesizedSampleIndex:1
.p.set[`synthesizedSampleIndex; synthesizedSampleIndex]
.p.set[`inputPDF; .ml.tab2df[(neg numSamplesToUse)#trainingData]] / take samples from end of table / take samples from end of table
/ \ts \l useGPRLiPoModel.p / deploy gaussian process regression model
\ts \l useELMLiPoModel.p / deploy ELM model
/ \l useSVRLiPoModel.p / use support vector regression model (To be implemented)
/ \l useAdaboostLiPoModel.p / use adaboost model (To be implemented)
/ \l useGradboostLiPoModel.p / train Gradient Boost model (To be implemented)
/ \l useXGBoostLiPoModel.p / train XGBoost model (To be implemented)
/ \l useRFLiPoModel.p / train adaboost model (To be implemented)
/ \l useStackGeneralizerLiPoModel.p / train Stack Generalizer model (To be implemented)
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
.p.set[`inputPDF; .ml.tab2df[(neg numSamplesToUse)#trainingData]] / take samples from end of table
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
numTimeSteps:10
.p.set[`syntheticSampleTimeDelta; syntheticSampleTimeDelta: 0.2] / in seconds
getSynthesizedDataCount:{flip `Sample`gpsSpeedPredictionTableRowCount`LiPoPredictionTableRowCount!enlist each (synthesizedSampleIndex-1),count each (gpsSpeedPredictionTable;LiPoPredictionTable)}
synthesizedDataCount: getSynthesizedDataCount[]
"calling FASSynthesizeSample.q"

/ create throttleInputHistory feature in current prediction tables for usage in feature synthesis
update throttleInputHistory:rcCommand3 from `LiPoPredictionTable
update throttleInputHistory:rcCommand3 from `gpsSpeedPredictionTable

/ synthesize timesteps by numTimeSteps
/ need to cut 1 from timestep as 1 sample is already generated during model deployment
{system "l FASSynthesizeSample.q"} each 1_til numTimeSteps;

/ EACH TIMESTEP SHOULD CONSIDER BOTH SPEED AND VOLTAGE PREDICTIONS. I.E DROP VOLTAGE FEATURE FROM GPS PREDICTION DF AND VICE VERSA, THEN JOIN THE TWO PREDICTION TABLES TOGETHER

/ clean up synthesized sample index in tables
`synthesizedSampleIndex xasc `LiPoPredictionTable;
/ delete duplicates from LiPoPredictionTable where synthesizedSampleIndex is 1
delete from `LiPoPredictionTable where i<((throttleSteps+1)*neg numSamplesToUse);

/ clean up synthesizedSampleIndex column (remove duplicated values in each row)
update synthesizedSampleIndex:first each synthesizedSampleIndex from `LiPoPredictionTable;
delete GPSspeedkph from `LiPoPredictionTable;
update synthesizedSampleIndex:first each synthesizedSampleIndex from `gpsSpeedPredictionTable;
delete vbatLatestV from `gpsSpeedPredictionTable;

/ key each table in preparation for inner join
keyTableFeatures: `synthesizedSampleIndex`throttleInputSequence`timeus`rcCommand3`timeDeltaus / possible columns: `vbatLatestV`gyroADC0`gyroADC1`gyroADC2`accSmooth0`accSmooth1`accSmooth2`motor0`motor1`motor2`motor3`GPSspeedkph`throttleInputSequence`synthesizedSampleIndex
keyTableFeatures xkey `gpsSpeedPredictionTable;
keyTableFeatures xkey `LiPoPredictionTable;
fullPredictionTable:LiPoPredictionTable ij gpsSpeedPredictionTable;
0!`fullPredictionTable; / unkey new table after join
fullPredictionTable: `vbatLatestV xcols fullPredictionTable
fullPredictionTable: `GPSspeedkph xcols fullPredictionTable
/save updated fullPredictionTable table
(hsym `$flatDir,"fullPredictionTable") set fullPredictionTable; / use hsym t cast directory string to file symbol

/////Select optimal training sequences from synthesized for LSTM Training/////
/ determine optimal throttle sequence by ranking leaf of synthesized sample sequence (tree data structure)
lookbackSteps:numTimeSteps
//
/ ASSUMING TABLE IS ORDERED WITH LATEST SAMPLE LAST
//
/ \ts throttleHistoryLengthOfLeaf:count (last fullPredictionTable)[`throttleInputHistory]
/ find throttle history length of each synthesized sample
throttleHistoryLength: count each (raze each select throttleInputHistory from fullPredictionTable)
throttleHistoryLengthOfLeaf:last throttleHistoryLength
/ determine samples which are leafs of the tree (end of cascade sequence)
leafIndices:asc where throttleHistoryLength=throttleHistoryLengthOfLeaf
optimalSequencesPercentage:0.2 / Top percentile to keep/regard as "optimal throttle sequences"
/ create LSTM training dataset from leaf samples
bestPredictionsTable:select currentThrottle:rcCommand3, GPSspeedkph,vbatLatestV, previousThrottleSequence:({lookbackSteps#x} each throttleInputHistory),throttleInputHistory from fullPredictionTable where i within (first leafIndices; last leafIndices)
`GPSspeedkph xasc `bestPredictionsTable;
/ remove non-optimal throttle sequences
bestPredictionsTable:(`int$optimalSequencesPercentage*count bestPredictionsTable)#bestPredictionsTable
/ available features in fullPredictionTable: `GPSspeedkph`vbatLatestV`synthesizedSampleIndex`throttleInputSequence`timeus`rcCommand3`timeDeltaus`currentSampleHz`rcCommand0`rcCommand1`rcCommand2`gyroADC0`gyroADC1`gyroADC2`accSmooth0`accSmooth1`accSmooth2`motor0`motor1`motor2`motor3`throttleInputHistory

/////Encode throttle sequences into format usable by LSTM models/////
/ encode end of sequence to each throttle sequencesample with lookbackSteps#0
fillValue:0
encodedOptimalThrottles: select throttleInputHistory:(throttleInputHistory,'(count bestPredictionsTable)#enlist ((lookbackSteps+1)#fillValue)) from bestPredictionsTable
/ flatten all samples into single time series
encodedOptimalThrottles: raze raze encodedOptimalThrottles[`throttleInputHistory]
/ Encoding format A: Create sliding window for samples and labels 
/
/ Calculating sliding window using step by step method (method a)
/ https://stackoverflow.com/questions/44071613/understanding-moving-window-calcs-in-kdb
/ cut non-valid samples from start
optimalThrottleSlidingWindowX: (lookbackSteps)_{1_x,y}\[(lookbackSteps)#0;encodedOptimalThrottles] / training time sequence feature
/ take last throttle value from each throttle sequence
optimalThrottleSlidingWindowy:last each (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;encodedOptimalThrottles] / training label
/ create LSTM trainingData table
/ LSTMTrainingData:flip `throttleSeries`expectedThrottle!((lookbackSteps)_encodedOptimalThrottles;optimalThrottleSlidingWindowy) / declaring using dict !
synthesizedThrottleLSTMTrainingData:([]throttleSeries:(lookbackSteps+1)_encodedOptimalThrottles; expectedThrottle:-1_optimalThrottleSlidingWindowy) / declaring using table-definition syntax
\

/ Encoding format A: calculate using direct timeshift transformation (method b, faster)
/
/ cut first row due to wrong data appearing
synthesizedThrottleLSTMTrainingData:1_([]throttleSeries:1_encodedOptimalThrottles; expectedThrottle:-1_encodedOptimalThrottles) / declaring using table-definition syntax
/ save copy of synthesizedThrottleLSTMTrainingData as csv
if[saveCSVs;save `:synthesizedThrottleLSTMTrainingData.csv;show "synthesizedThrottleLSTMTrainingData.csv saved to disk"]
\

/ Encoding format B: throttle series feature contains all throttle series within lookback window. expectedThrottle contains the next expected throttle
/
optimalThrottleSlidingWindow: (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;encodedOptimalThrottles] / training label
synthesizedThrottleLSTMTrainingDataMatrix:([]throttleSeries:-1_'optimalThrottleSlidingWindow;expectedThrottle:-1#'optimalThrottleSlidingWindow)
/remove rows with invalid prediction throttle sequences due to timeshift effect
/ delete from synthesizedThrottleLSTMTrainingDataMatrix where expectedThrottle=0 / bug with query
\

/ Encoding format C: each timestep is a feature
optimalThrottleSlidingWindow: (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;encodedOptimalThrottles] / training label
columns:{x} each flip optimalThrottleSlidingWindow
synthesizedThrottleLSTMTrainingDataMatrix: flip ((lookbackSteps+1)#{`$x}each .Q.a)!columns
/remove rows with invalid prediction throttle sequences due to timeshift effect
/ perform functional query equivalent for "delete from `synthesizedThrottleLSTMTrainingDataMatrix where (last cols synthesizedThrottleLSTMTrainingDataMatrix)=0" as qsql does not support column names as variables
![`synthesizedThrottleLSTMTrainingDataMatrix;enlist (=;last cols synthesizedThrottleLSTMTrainingDataMatrix;0);0b;`symbol$()];

///For diagnostics with LSTM model/////
"Saving synthesizedThrottleLSTMTrainingDataMatrix to disk"
p)from joblib import dump
.p.set[`synthesizedThrottleLSTMTrainingDataMatrix; .ml.tab2df[synthesizedThrottleLSTMTrainingDataMatrix]]
p)dump(synthesizedThrottleLSTMTrainingDataMatrix, 'synthesizedThrottleLSTMTrainingDataMatrix.joblib')

/////Select throttle time series sequence from real flight logs for LSTM Training/////
realThrottles:trainingData[`rcCommand3]
/
/ Encoding format A: Create sliding window for samples and labels 
/ calculate using step by step method (method a)
realThrottleSlidingWindowX:(lookbackSteps)_{1_x,y}\[(lookbackSteps)#0;realThrottles] / training time sequence feature
realThrottleSlidingWindowy:last each (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;realThrottles] / training label
realThrottleLSTMTrainingData:([]throttleSeries:(lookbackSteps+1)_realThrottles; expectedThrottle:-1_realThrottleSlidingWindowy) / declaring using table-definition syntax
\

/ Encoding format A: calculate using direct timeshift transformation (method b, faster)
/
realThrottleLSTMTrainingData:1_([]throttleSeries:1_realThrottles; expectedThrottle:-1_realThrottles) / declaring using table-definition syntax
if[saveCSVs;save `:realThrottleLSTMTrainingData.csv;show "realThrottleLSTMTrainingData.csv saved to disk"]
\

/ Encoding format B: throttle series feature contains all throttle series within lookback window. expectedThrottle contains the next expected throttle
realThrottleSlidingWindow: (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;realThrottles] / training label
realThrottleLSTMTrainingDataMatrix:([]throttleSeries:-1_'realThrottleSlidingWindow;expectedThrottle:-1#'realThrottleSlidingWindow)
/remove rows with invalid prediction throttle sequences due to timeshift effect
/ parse "delete from realThrottleLSTMTrainingDataMatrix where (last cols realThrottleLSTMTrainingDataMatrix)=0" / bug with query
/ ![`realThrottleLSTMTrainingDataMatrix;enlist (=;(last;(k){$[.Q.qp x:.Q.v x;.Q.pf,!+x;98h=@x;!+x;11h=@!x;!x;!+0!x]};`realThrottleLSTMTrainingDataMatrix));0);0b;`symbol$()]/ bug with query


/ Encoding format C: each timestep is a feature
realThrottleSlidingWindow: (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;realThrottles] / training label
columns:{x} each flip realThrottleSlidingWindow
realThrottleLSTMTrainingDataMatrix: flip ((lookbackSteps+1)#{`$x}each .Q.a)!columns
/remove rows with invalid prediction throttle sequences due to timeshift effect
/ perform functional query equivalent for "delete from `realThrottleLSTMTrainingDataMatrix where (last cols realThrottleLSTMTrainingDataMatrix)=0" as qsql does not support column names as variables
![realThrottleLSTMTrainingDataMatrix;enlist(=;last cols realThrottleLSTMTrainingDataMatrix;0);0b;`symbol$()];

///For diagnostics with LSTM model/////
"Saving realThrottleLSTMTrainingDataMatrix to disk"
p)from joblib import dump
.p.set[`realThrottleLSTMTrainingDataMatrix; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]]
p)dump(realThrottleLSTMTrainingDataMatrix, 'realThrottleLSTMTrainingDataMatrix.joblib')

/ https://towardsdatascience.com/time-series-forecasting-with-recurrent-neural-networks-74674e289816

/////Train LSTM models/////
/////Reference Material Used/////
/ https://machinelearningmastery.com/time-series-prediction-lstm-recurrent-neural-networks-python-keras/

trainUsingSynthesizedData: 0b
trainUsingRealData: not trainUsingSynthesizedData
/ system "l updateRegressionLSTM.p"
LSTMModel: `regressionNormal / options: `regressionNormal `regressionWindow `regressionTimeStep `batch `Disabled
/ Real Data Input, LSTM Regression / Using encoding format C
if[trainUsingRealData and LSTMModel = `regressionNormal;.p.set[`trainingDataPDF; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Normal) using real flight data!"; system "l updateRegressionLSTM.p"]
/ Real Data Input, LSTM Regression using Window / Using encoding format C
if[trainUsingRealData and LSTMModel = `regressionWindow;.p.set[`trainingDataPDF; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Window) using real flight data!"; system "l updateRegressionWindowLSTM.p"]
/ Real Data Input, LSTM Regression with Time Step / Using encoding format C
if[trainUsingRealData and LSTMModel = `regressionTimeStep;.p.set[`trainingDataPDF; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Time Step) using real flight data!"; system "l updateRegressionTimeStepLSTM.p"]
/ Real Data Input, LSTM with Memory Between Batches / Using encoding format C
if[trainUsingRealData and LSTMModel = `batch;.p.set[`trainingDataPDF; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Memory Between Batches) using real flight data!"; system "l updateMemoryLSTM.p"]

/ Synthesized Data Input, LSTM Regression / Using encoding format C
if[trainUsingSynthesizedData and LSTMModel = `regressionNormal;.p.set[`trainingDataPDF; .ml.tab2df[synthesizedThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Normal) using synthesized data!"; system "l updateRegressionLSTM.p"]
/ Synthesized Data Input, LSTM Regression using Window / Using encoding format C (To be implemented)
if[trainUsingSynthesizedData and LSTMModel = `regressionWindow;.p.set[`trainingDataPDF; .ml.tab2df[synthesizedThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Window) using synthesized data!"; system "l updateRegressionWindowLSTM.p"]
/ Synthesized Data Input, LSTM Regression with Time Step / Using encoding format C (To be implemented)
if[trainUsingSynthesizedData and LSTMModel = `regressionTimeStep;.p.set[`trainingDataPDF; .ml.tab2df[synthesizedThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Time Step) using synthesized data!"; system "l updateRegressionTimeStepLSTM.p"]
/ Synthesized Data Input, LSTM with Memory Between Batches / Using encoding format C (To be implemented)
if[trainUsingSynthesizedData and LSTMModel = `batch;.p.set[`trainingDataPDF; .ml.tab2df[synthesizedThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Memory Between Batches) using synthesized data!";system "l updateMemoryLSTM.p"]

if [LSTMModel=`Disabled; show "LSTM training disabled"]

/////Test Deploy trained LSTM model/////
.p.set[`inputPDF; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]]
\ts system "l useLSTM.p"

"Completed Updating Models"