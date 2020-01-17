trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);testPercentage:0.2]
trainTestSplitTrainingData[`xtest] / test set

/actual model deployment
numSamplesToUse:5
.p.set[`inputPDF; .ml.tab2df[(neg(numSamplesToUse))#trainingData]] / take last numSamplesToUse
/ save `:trainingDataPDF.csv
\l useLinearGPSModel.p

/convert prediction result back to q list
pythonVar:.p.pyget`gpsSpeedPredictions
gpsSpeedPrediction:.p.py2q pythonVar