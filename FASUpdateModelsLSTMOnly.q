/ retrieve latest training data using synchronous IPC
trainingData:h"trainingData"

useTrainTestSplit:0b

//////split dataset into training and test data//////
trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);testPercentage:0]
testingSamples:(til count dataset) except (trainingSamples:where dataset:trainTestSplitTrainingData[`ytrain]=1b)
trainTestSplitAssignmentTable:`testingSamples`trainingSamples!(testingSamples;trainingSamples);
/ give python access to training data panda dataframe
if[useTrainTestSplit;.p.set[`trainingDataPDF; .ml.tab2df[trainTestSplitTrainingData[`xtrain]]];show "Using train test split!"]
if[not useTrainTestSplit;.p.set[`trainingDataPDF; .ml.tab2df[trainingData]];show "Not using train test split!"]

/ Train LSTM
numTimeSteps:10
lookbackSteps:numTimeSteps
realThrottles:trainingData[`rcCommand3]

/////cap throttle value to [1000, 2000] and normalise to [0,1]////
realThrottles: {min[2000,x]} each realThrottles
realThrottles: {max[1000,x]} each realThrottles
realThrottles-:1000
realThrottles%:1000

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
LSTMModel: `regressionWindow / options: `regressionWindow `regressionTimeStep `batch `Disabled
/ Real Data Input, LSTM Regression / Using encoding format C
/ Real Data Input, LSTM Regression using Window / Using encoding format C
if[trainUsingRealData and LSTMModel = `regressionWindow;.p.set[`trainingDataPDF; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Window) using real flight data!"; system "l updateRegressionWindowLSTM.p"]
/ Real Data Input, LSTM Regression with Time Step / Using encoding format C
if[trainUsingRealData and LSTMModel = `regressionTimeStep;.p.set[`trainingDataPDF; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Time Step) using real flight data!"; system "l updateRegressionTimeStepLSTM.p"]
/ Real Data Input, LSTM with Memory Between Batches / Using encoding format C
if[trainUsingRealData and LSTMModel = `batch;.p.set[`trainingDataPDF; .ml.tab2df[realThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Memory Between Batches) using real flight data!"; system "l updateMemoryLSTM.p"]

/ Synthesized Data Input, LSTM Regression / Using encoding format C
/ Synthesized Data Input, LSTM Regression using Window / Using encoding format C (To be implemented)
if[trainUsingSynthesizedData and LSTMModel = `regressionWindow;.p.set[`trainingDataPDF; .ml.tab2df[synthesizedThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Window) using synthesized data!"; system "l updateRegressionWindowLSTM.p"]
/ Synthesized Data Input, LSTM Regression with Time Step / Using encoding format C (To be implemented)
if[trainUsingSynthesizedData and LSTMModel = `regressionTimeStep;.p.set[`trainingDataPDF; .ml.tab2df[synthesizedThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Regression Time Step) using synthesized data!"; system "l updateRegressionTimeStepLSTM.p"]
/ Synthesized Data Input, LSTM with Memory Between Batches / Using encoding format C (To be implemented)
if[trainUsingSynthesizedData and LSTMModel = `batch;.p.set[`trainingDataPDF; .ml.tab2df[synthesizedThrottleLSTMTrainingDataMatrix]];show "Training LSTM (Memory Between Batches) using synthesized data!";system "l updateMemoryLSTM.p"]

if [LSTMModel=`Disabled; show "LSTM training disabled"]

/////Test Deploy trained LSTM model/////
.p.set[`inputPDF; .ml.tab2df[(neg lookbackSteps)#realThrottleLSTMTrainingDataMatrix]]
\l useRegressionWindowLSTM.p
yPred:.p.py2q .p.pyget`yPred

/ if using cloud kdb server, transfer updated LSTM model to using ssh
if[(h>0) and hostPort = hsym `renxiang.cloud:5001; system"l trainedLSTMModelTransfer.p"; show "Transferring newly trained LSTM model to cloud!"]

/ h (`clearyPredTable;0) / clear yPredTable on Server
/ Do not insert predictions back to server during live deployment!
/ {h (`insertyPredTable;x)} each yPred / insert new predictions to yPredTable on Server
/ neg[h] (`showyPredTable;0) / show updated yPredTable on Server 
/ To ensure an async message is sent immediately, flush the pending outgoing queue for handle h
/ neg[h][]
/ To ensure an async message has been processed by the remote, follow with a sync chaser
/ h"";

"Completed Updating Models"
/ if[hostPort = hsym `:renxiang.cloud:5001; ]
neg[h] (`receiveUpdatedModels;0)
