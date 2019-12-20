/train test split example
trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);0.2]
tempTable:flip (`index; `match)!(til count(trainTestSplitTrainingData[`ytrain]) ; trainTestSplitTrainingData[`ytrain])
indexOfRowsUsedForTraining: raze flip select index from tempTable where match = 1
indexOfRowsUsedForTesting: raze flip select index from tempTable where match = 0

/ trainingDataPDF: .ml.tab2df[trainingData]
.p.set[`trainingDataPDF; .ml.tab2df[trainTestSplitTrainingData[`xtrain]]]

/ save `:trainingDataPDF.csv
\l updateModels.p

"Verifying models"
/actual model deployment
.p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]]
\l useModels.p

/need to reset inputPDF due to manipulation by model
.p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]]
\l verifyModels.p

/convert prediction result back to q list
pythonVar:.p.pyget`gpsSpeedPredictions
gpsSpeedPrediction:.p.py2q pythonVar

/ gpsSpeedPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF