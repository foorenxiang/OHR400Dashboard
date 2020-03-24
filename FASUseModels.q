/ number of look ahead samples for training LSTM

/////Select throttle time series sequence from real flight logs for LSTM Training/////
realThrottles:trainingData[`rcCommand3]

/////cap throttle value to [1000, 2000] and normalise to [0,1]////
realThrottles: {min[2000,x]} each realThrottles
realThrottles: {max[1000,x]} each realThrottles
realThrottles-:1000
realThrottles%:1000

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
/
realThrottleSlidingWindow: (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;realThrottles] / training label
realThrottleLSTMTrainingDataMatrix:([]throttleSeries:-1_'realThrottleSlidingWindow;expectedThrottle:-1#'realThrottleSlidingWindow)
\

/ Encoding format C: each timestep is a feature
realThrottleSlidingWindow: (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;realThrottles] / training label
columns:{x} each flip realThrottleSlidingWindow
realThrottleLSTMTrainingDataMatrix: flip ((lookbackSteps+1)#{`$x}each .Q.a)!columns
/remove rows with invalid prediction throttle sequences due to timeshift effect
/ perform functional query equivalent for "delete from `realThrottleLSTMTrainingDataMatrix where (last cols realThrottleLSTMTrainingDataMatrix)=0" as qsql does not support column names as variables
![realThrottleLSTMTrainingDataMatrix;enlist(=;last cols realThrottleLSTMTrainingDataMatrix;0);0b;`symbol$()];

/ LSTMModel: `regressionWindow / options: `regressionWindow `regressionTimeStep `batch `Disabled

/////Test Deploy trained LSTM model/////
.p.set[`inputPDF; .ml.tab2df[(neg lookbackSteps)#realThrottleLSTMTrainingDataMatrix]]
\l useRegressionWindowLSTM.p

/
trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);testPercentage:0.2]
trainTestSplitTrainingData[`xtest] / test set

/actual model deployment
numSamplesToUse: 
.p.set[`inputPDF; .ml.tab2df[(neg(numSamplesToUse))#trainingData]] / take last numSamplesToUse
/ save `:trainingDataPDF.csv
\l useLinearGPSModel.p

/convert prediction result back to q list
pythonVar:.p.pyget`gpsSpeedPredictions
gpsSpeedPrediction:.p.py2q pythonVar
\