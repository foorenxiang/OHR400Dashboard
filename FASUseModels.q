FASUseModels:{
	/ retrieve latest training data
	sampleCaptureTime:.z.z;
	trainingData:h"trainingData";
	/ `lookbackSteps defined in FASInit.q's load value or updated during model retraining
	/////Select throttle time series sequence from real flight logs for LSTM Training/////
	realThrottles:(neg 3+lookbackSteps)#trainingData[`rcCommand3];
	realThrottlesOriginal:realThrottles;
	/ skip prediction if throttle values are missing in data stream
	if[0n in realThrottles; `p];
	/////normalise to [0,1]////
	/disable capping of throttle range to [1000,2000] using below q function unless required as it adds 3ms of delay
	/ \ts realThrottles: {min[2000,x]} each realThrottles 
	/ \ts realThrottles: {max[1000,x]} each realThrottles
	realThrottles-:1000;
	realThrottles%:1000;
	/ Encoding format C: each timestep is a feature
	realThrottleSlidingWindow: (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;realThrottles]; / training label
	columns:{x} each flip realThrottleSlidingWindow;
	realThrottleLSTMTrainingDataMatrix: flip ((lookbackSteps+1)#{`$x}each .Q.a)!columns;
	/remove rows with invalid prediction throttle sequences due to timeshift effect
	/ perform functional query equivalent for "delete from `realThrottleLSTMTrainingDataMatrix where (last cols realThrottleLSTMTrainingDataMatrix)=0" as qsql does not support column names as variables
	![realThrottleLSTMTrainingDataMatrix;enlist(=;last cols realThrottleLSTMTrainingDataMatrix;0);0b;`symbol$()];
	/ LSTMModel: `regressionWindow / options: `regressionWindow `regressionTimeStep `batch `Disabled
	/////Test Deploy trained LSTM model/////
	.p.set[`inputPDF; .ml.tab2df[(neg lookbackSteps)#realThrottleLSTMTrainingDataMatrix]];
	system"l useRegressionWindowLSTM.p";
	yPred:raze .p.py2q .p.pyget`yPred;
	/ create table with GMT timestamp of prediction and y predictions
	/ yPredtimeStamp:{.z.t + 200* til lookbackSteps}
	yPredtimeStamp:.z.z;
	yPredTable:flip `serverTimeAtPrediction`sequence`throttlePrediction`serverTimeAtCapture`refThrottlesSequence`refThrottles!(yPredtimeStamp;til lookbackSteps;yPred;sampleCaptureTime;til lookbackSteps;(neg lookbackSteps)#realThrottlesOriginal);
	neg[h] (`insertyPredTable;yPredTable); / insert new predictions to yPredTable on Server
	/ To ensure an async message is sent immediately, flush the pending outgoing queue for handle h
	neg[h][];
	/ To ensure an async message has been processed by the remote, follow with a sync chaser
	h"";
	neg[h] (`showyPredTable;0); / show updated yPredTable on Server 
	/ To ensure an async message is sent immediately, flush the pending outgoing queue for handle h
	neg[h][];}