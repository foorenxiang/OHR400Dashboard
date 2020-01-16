/ train test split example
trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);0.2]
tempTable:flip (`index; `match)!(til count(trainTestSplitTrainingData[`ytrain]) ; trainTestSplitTrainingData[`ytrain])
indexOfRowsUsedForTraining: raze flip select index from tempTable where match = 1
indexOfRowsUsedForTesting: raze flip select index from tempTable where match = 0

/ give python access to training data panda dataframe
.p.set[`trainingDataPDF; .ml.tab2df[trainTestSplitTrainingData[`xtrain]]]

////// train gps prediction model
/ \l updateLinearGPSModel.p / train linear model
\l updateGPRGPSModel.p / train gaussian process regression model
/ \l updateELMGPSModel.p / train Extreme Learning Machine model

////// actual model deployment
/ give python access to testing data panda dataframe
.p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]]

////// deploy gps model
/ \l useLinearGPSModel.p / deploy linear model
\l useGPRGPSModel.p / deploy gaussian process regression model

////// need to reset inputPDF due to manipulation by model
.p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]]

"Verifying models"
/ \l verifyLinearGPSModel.p

/ convert prediction result back to q list
pythonVar:.p.pyget`gpsSpeedPrediction
gpsSpeedPrediction:.p.py2q pythonVar

/ results from GPR model
gpsSpeedPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF