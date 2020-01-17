/ apply train test split to dataset
trainTestSplitTrainingData:.ml.traintestsplit[trainingData;(count trainingData)?(0b;1b);testPercentage:0.2]
testingSamples:(til count dataset) except (trainingSamples:where dataset:trainTestSplitTrainingData[`ytrain]=1b)
`testingSamples`trainingSamples!(testingSamples;trainingSamples)

/ give python access to training data panda dataframe
.p.set[`trainingDataPDF; .ml.tab2df[trainTestSplitTrainingData[`xtrain]]]

//////TRAIN GPS PREDICTION MODEL//////
// train gps prediction model 
\l updateGPRGPSModel.p / train gaussian process regression model
/ \l updateELMGPSModel.p / train Extreme Learning Machine model
/ \l updateLinearGPSModel.p / train linear model
//////TRAIN GPS PREDICTION MODEL//////

//////TRAIN LIPO PREDICTION MODEL//////
.p.set[`trainingDataPDF; .ml.tab2df[trainTestSplitTrainingData[`xtrain]]]
\l updateGPRLiPoModel.p / train gaussian process regression model
//////TRAIN LIPO PREDICTION MODEL//////

/ define number of samples to 
numSamplesToUse:5
numSamplesToUse:(neg(numSamplesToUse)) / take samples from end of table

//////DEPLOY GPS MODEL//////
/ give python access to testing data panda dataframe
/ always call .p.set to ensure model receives fresh panda dataframe
/ .p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]] / use this input to test the model
.p.set[`inputPDF; .ml.tab2df[numSamplesToUse#trainingData]]
\l useGPRGPSModel.p / deploy gaussian process regression model
/ \l useLinearGPSModel.p / deploy linear model
/ convert prediction result from python object back to q list
gpsSpeedPrediction:.p.py2q .p.pyget`gpsSpeedPrediction
gpsSpeedPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF	
//////DEPLOY GPS MODEL//////

//////DEPLOY LIPO MODEL//////
/ give python access to testing data panda dataframe
/ always call .p.set to ensure model receives fresh panda dataframe
/ .p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]] / use this input to test the model
.p.set[`inputPDF; .ml.tab2df[numSamplesToUse#trainingData]]
\l useGPRLiPoModel.p / deploy gaussian process regression model
/ convert prediction result from python object back to q list
LiPoPrediction:.p.py2q .p.pyget`LiPoPrediction
LiPoPredictionTable:.ml.df2tab .p.wrap .p.pyget`LiPoPredictionPDF
//////DEPLOY LIPO MODEL//////

//////VERIFY MODELS//////

///VERIFY GPS MODEL///
/ .p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]] / use this input to test the model
/ \l useLinearGPSModel.p / deploy linear model
/ \l useGPRGPSModel.p / deploy gaussian process regression model
/ convert prediction result from python object back to q list
gpsSpeedPrediction:.p.py2q .p.pyget`gpsSpeedPrediction
gpsSpeedPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF	
///VERIFY GPS MODEL///

///VERIFY LIPO MODEL///
/ always call .p.set to ensure model receives fresh panda dataframe
/ .p.set[`inputPDF; .ml.tab2df[trainTestSplitTrainingData[`xtest]]] / use this input to test the model
.p.set[`inputPDF; .ml.tab2df[numSamplesToUse#trainingData]]
\l useGPRLiPoModel.p / deploy gaussian process regression model
/ convert prediction result from python object back to q list
LiPoPrediction:.p.py2q .p.pyget`LiPoPrediction
LiPoPredictionTable:.ml.df2tab .p.wrap .p.pyget`LiPoPredictionPDF
///VERIFY LIPO MODEL///

//////VERIFY MODELS//////

//////Synthesize time series data from traing LSTM network//////
.p.set[`inputPDF; .ml.tab2df[delete inputSequence from LiPoPredictionTable]]
\l useGPRGPSModel.p / deploy gaussian process regression model
gpsSpeedPrediction:.p.py2q .p.pyget`gpsSpeedPrediction
gpsSpeedPredictionTable:.ml.df2tab .p.wrap .p.pyget`gpsPredictionPDF

.p.set[`inputPDF; .ml.tab2df[delete inputSequence from gpsSpeedPredictionTable]]
\l useGPRLiPoModel.p / deploy gaussian process regression model
LiPoPrediction:.p.py2q .p.pyget`LiPoPrediction
LiPoPredictionTable:.ml.df2tab .p.wrap .p.pyget`LiPoPredictionPDF
//////Synthesize time series data from traing LSTM network//////

//////SANDBOX AREA//////
/ -1 "SANDBOX AREA ACTIVE"
/ (cols delete inputSequence from trainTestSplitTrainingData[`xtrain]) except (cols LiPoPredictionTable)
/ (cols delete inputSequence from LiPoPredictionTable) except (cols trainTestSplitTrainingData[`xtrain])
/ (cols ([] col1:`a`b; col2:1 2)) except cols ([] col3:`a`b; col4:1 2)
