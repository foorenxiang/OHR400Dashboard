#deploy model
#this model will apply pseudo throttle values from 1000 to 2000us and create variations of single input sample
#GPS speed will be predicted for each synthesized sample
#output is stored as gpsPredictionPDF (retrievable from kdb through shared python space)

import sys
import numpy as np
import pandas as pd
import sklearn.gaussian_process as gp
from joblib import load  #model persistance library
from sklearn.preprocessing import StandardScaler

fileName = 'useGPRGPSModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Using ELM GPS Model'
print(comments)

def mse(pred, actual):
	return ((pred-actual)**2).mean()


def strFloat(floatVal):
	return "{0:.2f}".format(round(floatVal,2))

#fallback csv training data if not using kdb data (for testing purposes)
csvTrainingData = 'trainingDataAbove100kph.csv' #will not be used if kdb input is detected when running this script

trainingDataPDFNotFound = False
if 'trainingDataPDF' not in globals():
	trainingDataPDFNotFound = True

if trainingDataPDFNotFound == True:
	trainingDataPDF = pd.read_csv(csvTrainingData)
	print("Testing GPS Speed using csv input!")

#using else or try catch causes bugs with embedpy
if trainingDataPDFNotFound == False:
	trainingSetName = "KDB+ Input"
	print("Predicting GPS Speed using KDB+ input!")

if 'synthesizedSampleIndex' not in globals():
	synthesizedSampleIndex = 0

if 'numSamplesToUse' not in globals():
	numSamplesToUse = 10

trainPercentage = 0.7 # not in use
trainingDataTrain = trainingDataPDF[:int(trainPercentage*len(trainingDataPDF))] # not in use

pd.set_option('display.max_rows', None)

#if not importing data from kdb+ (testing purposes)
if 'inputPDF' not in globals():
	inputPDF = trainingDataTrain.copy()
	print("importing data from csv source") 

# inputPDF = trainingDataTrain.copy()

#select number of samples used for prediction
#COMMENT OUT WHEN USING WITH KDB+!!!
# numSamplesToUse = 1 
# inputPDF = inputPDF.tail(numSamplesToUse)

#drop actual throttle data for prediction
inputPDF.drop(['GPSspeedkph'], axis=1, inplace = True)
# inputPDF = inputPDF[['rcCommand0', 'rcCommand1', 'rcCommand3']]

#predict gps speed for range of throttle values
if 'lowThrottle' not in globals():
	lowThrottle = 1000

if 'highThrottle' not in globals():
	highThrottle = 2000

if 'throttleSteps' not in globals():
	throttleSteps = 10

#prepare throttle variations vector and parameters
steps = (highThrottle - lowThrottle) / throttleSteps
steps = int(steps)
highThrottle+=1
throttleInputRange = list(range(lowThrottle,highThrottle, steps))
throttleInputRange.reverse()
print("throttleInputRange")
print(throttleInputRange)

#prepare dataframe for throttle variations input
tempPDF = inputPDF.copy()
# print("tempPDF")
# print(tempPDF)
for x in range(throttleSteps):
	inputPDF = inputPDF.append(tempPDF)
inputPDF.reset_index(inplace=True)
inputPDF.loc[:,['rcCommand3']] = 1000
inputPDF.drop(['index'], axis=1, inplace = True)

# print("Throttle range: ")
# for x in range(len(throttleInputRange)):
	# print(throttleInputRange[x])

# generate list of input data with varying throttle ranges for speed prediction
for x in range(len(throttleInputRange)):
	for y in range(numSamplesToUse):
		# print("index: " + str(x*numSamplesToUse+y))
		inputPDF.loc[[x*numSamplesToUse+y],'rcCommand3'] = throttleInputRange[x]
# print("inputPDF columns:")
# print(inputPDF.columns)
#run model to get speed predictions

#normalise with Standard Scalar for use with ELM
inputPDFStandardScalar = StandardScaler()
tempInputPDF = inputPDFStandardScalar.fit_transform(inputPDF)

modelSave = load('elmGPSSpeedModel.model')
model = modelSave["model"]
usePCA = modelSave["usePCA"]
yStandardScalar = modelSave["yStandardScalar"]

######if using PCA, determine principal components######
if 'usePCA' in globals():
	if usePCA:
		print("Using PCA!")
		pcaModel = modelSave["pcaModel"]
		tempInputPDF = pd.DataFrame(pcaModel.transform(tempInputPDF))
if not 'usePCA' in globals():
	print("Not using PCA!")
######if using PCA, determine principal components######

gpsSpeedPrediction = model.predict(tempInputPDF)
gpsSpeedPrediction = yStandardScalar.inverse_transform(gpsSpeedPrediction)
gpsSpeedPrediction = pd.Series(gpsSpeedPrediction.flatten())
# print("gpsSpeedPrediction:")
# print(gpsSpeedPrediction)

#inputPDF merge predicted values to new dataframe
gpsPredictionPDF = pd.merge(inputPDF, pd.Series(data=gpsSpeedPrediction, name='GPSspeedkph'), how='inner', on=None, left_on=None, right_on=None,
         left_index=True, right_index=True, sort=False,
         suffixes=('_x', '_y'), copy=True, indicator=False,
         validate=None)

#label with throttle scenario/throttleInputSequence
throttleInputSequence = list()
synthesizedSampleIndexRef, synthesizedSampleIndex = synthesizedSampleIndex, list()
for x in range(len(throttleInputRange)):
	for y in range(numSamplesToUse):
		throttleInputSequence.append(x)
		synthesizedSampleIndex.append(synthesizedSampleIndexRef)
# print('throttleInputSequence:')
# print(throttleInputSequence)
gpsPredictionPDF = pd.merge(gpsPredictionPDF, pd.Series(data=throttleInputSequence, name='throttleInputSequence'), how='inner', on=None, left_on=None, right_on=None,
         left_index=True, right_index=True, sort=False,
         suffixes=('_x', '_y'), copy=True, indicator=False,
         validate=None)
gpsPredictionPDF = pd.merge(gpsPredictionPDF, pd.Series(data=synthesizedSampleIndex, name='synthesizedSampleIndex'), how='inner', on=None, left_on=None, right_on=None,
         left_index=True, right_index=True, sort=False,
         suffixes=('_x', '_y'), copy=True, indicator=False,
         validate=None)
print('gpsPredictionPDF set')
# print(gpsPredictionPDF)
print('prediction complete!')
#retrieve predictionPDF using KDB+!