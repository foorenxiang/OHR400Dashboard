trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);0.2]
trainTestSplitTrainingData[`xtest] / test set


/actual model deployment
numOfSamples:5
.p.set[`inputPDF; .ml.tab2df[(neg(numOfSamples))#trainingData]] / take last numOfSamples
/ save `:trainingDataPDF.csv
\l useModels.p

/convert prediction result back to q list
pythonVar:.p.pyget`gpsSpeedPredictions
gpsSpeedPrediction:.p.py2q pythonVar