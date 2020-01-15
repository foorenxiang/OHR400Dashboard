#deploy model
import sys
import numpy as np
import pandas as pd
import sklearn.gaussian_process as gp
from joblib import load  #model persistance library

fileName = 'updateGPRGPSModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Using RationalQuadratic GPR kernel'

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
	print("Testing using csv input!")

#using else or try catch causes bugs with embedpy
if trainingDataPDFNotFound == False:
	trainingSetName = "KDB+ Input"
	print("Training using KDB+ input!")

trainPercentage = 0.7
trainingDataTrain = trainingDataPDF[:int(trainPercentage*len(trainingDataPDF))]




model = load('gprGPSSpeedModel.joblib')

pd.set_option('display.max_rows', None)

#if not importing data from kdb+ (testing purposes)
if 'inputPDF' not in globals():
	inputPDF = trainingDataTrain.copy() 

inputPDF = trainingDataTrain.copy()

#select number of samples used for prediction
numSamplesToUse = 1 #disable when using with KDB+!!!
inputPDF = inputPDF.tail(numSamplesToUse)

#drop actual throttle data for prediction
inputPDF.drop(['GPSspeedkph'], axis=1, inplace = True)
# inputPDF = inputPDF[['rcCommand0', 'rcCommand1', 'rcCommand3']]

#predict gps speed for range of throttle values
lowThrottle = 1000
highThrottle = 2000
throttleSteps = 20

#prepare throttle variations vector and parameters
steps = (highThrottle - lowThrottle) / throttleSteps
steps = int(steps)
highThrottle+=1
throttleInputRange = list(range(lowThrottle,highThrottle, steps))
throttleInputRange.reverse()

#prepare dataframe for throttle variations input
tempPDF = inputPDF.copy()
for x in range(throttleSteps):
	inputPDF = inputPDF.append(tempPDF)
inputPDF.reset_index(inplace=True)
inputPDF.loc[:,['rcCommand3']] = 1000
inputPDF.drop(['index'], axis=1, inplace = True)


# print("Throttle range: ")
# for x in range(len(throttleInputRange)):
# 	print(throttleInputRange[x])

# generate list of input data with varying throttle ranges for speed prediction
for x in range(len(throttleInputRange)):
	for y in range(numSamplesToUse):
		# print("index: " + str(x*numSamplesToUse+y))
		inputPDF.loc[[x*numSamplesToUse+y],'rcCommand3'] = throttleInputRange[x]

# print("inputPDF columns:")
# print(inputPDF.columns)

#run model to get speed predictions
gpsSpeedPrediction, covMatrix = model.predict(inputPDF, return_cov=True)

#inputPDF merge predicted values to new dataframe
gpsPredictionPDF = pd.merge(inputPDF, pd.Series(data=gpsSpeedPrediction, name='predictedGPSSpeedkph'), how='inner', on=None, left_on=None, right_on=None,
         left_index=True, right_index=True, sort=False,
         suffixes=('_x', '_y'), copy=True, indicator=False,
         validate=None)

#label with throttle scenario/inputSequence
inputSequence = list()
for x in range(len(throttleInputRange)):
	for y in range(numSamplesToUse):
		inputSequence.append(x)
print('inputSequence:')
print(inputSequence)
gpsPredictionPDF = pd.merge(gpsPredictionPDF, pd.Series(data=inputSequence, name='inputSequence'), how='inner', on=None, left_on=None, right_on=None,
         left_index=True, right_index=True, sort=False,
         suffixes=('_x', '_y'), copy=True, indicator=False,
         validate=None)
print('gpsPredictionPDF set')
print(gpsPredictionPDF)

#retrieve predictionPDF using KDB+!