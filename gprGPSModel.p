import pandas as pd
import sklearn.gaussian_process as gp
from joblib import dump, load  #model persistance library
import mysql.connector
import sys

pd.set_option('display.max_rows', None)

#mysql update setup variables
fileName = 'gprGPSModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Using RationalQuadratic GPR kernel'

def mse(pred, actual):
	return ((pred-actual)**2).mean()


def strFloat(floatVal):
	return "{0:.2f}".format(round(floatVal,2))


trainingDataPDF = pd.read_csv('trainingDataAbove100kph.csv') #comment out if importing data from kdb
# trainingDataPDF = pd.read_csv('trainingData.csv') #comment out if importing data from kdb
trainPercentage = 0.7
trainingDataTrain = trainingDataPDF[:int(trainPercentage*len(trainingDataPDF))]
trainingDataTest = trainingDataPDF[int(trainPercentage*len(trainingDataPDF)):]
inputPDF = trainingDataTest #comment out if importing data from kdb

# trainX <-- training observations [# points, # features]
# trainy <-- training labels [# points]
# testX <-- test observations [# points, # features]
# testy <-- test labels [# points]

trainX = trainingDataTrain.copy()
trainX.drop(['GPSspeedkph'], axis=1, inplace = True)
trainy = trainingDataTrain["GPSspeedkph"]
# Index(['timeDeltaus', 'currentSampleHz', 'timeus', 'rcCommand0', 'rcCommand1',
       # 'rcCommand2', 'rcCommand3', 'vbatLatestV', 'gyroADC0', 'gyroADC1',
       # 'gyroADC2', 'accSmooth0', 'accSmooth1', 'accSmooth2', 'motor0',
       # 'motor1', 'motor2', 'motor3'],
      # dtype='object')

testX = trainingDataTest.copy()
testX.drop(['GPSspeedkph'], axis=1, inplace = True)
testy = trainingDataTest["GPSspeedkph"]


#using constant gpr kernel
# kernel = gp.kernels.ConstantKernel() * gp.kernels.RBF()
kernel = gp.kernels.RationalQuadratic()





print("GPR Kernel used:")
print(kernel)

model = gp.GaussianProcessRegressor(kernel=kernel, n_restarts_optimizer=10, alpha=0.001, normalize_y=True)

model.fit(trainX, trainy)
modelParams = model.kernel_.get_params() #call this to retrieve tuned hyperparameters from model
print("Model params:")
print(modelParams)

savedGPSSpeedModelGPR = dump(model, 'gprGPSSpeedModel.joblib')

model = 0 

#test model
model = load('gprGPSSpeedModel.joblib')
# print(testX.columns)
y_pred, covMatrix = model.predict(testX, return_cov=True)

#calculate mean square error
MSE = mse(y_pred,testy)

#display mean square error
# print("Actual vs Predictions:")
# testy = testy.to_numpy()
# for i in range(len(y_pred)):
# 	print(strFloat(testy[i]) + " || " + strFloat(y_pred[i]))
print("Mean Square Error:")
print(strFloat(MSE))

#deploy model

#psuedo data to work with
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
y_pred, covMatrix = model.predict(inputPDF, return_cov=True)

#inputPDF merge predicted values to new dataframe
gpsPredictionPDF = pd.merge(inputPDF, pd.Series(data=y_pred, name='predictedGPSSpeedkph'), how='inner', on=None, left_on=None, right_on=None,
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

#retrieve predictionPDF from KDB+!

#save model setup to mysql db
# conn = mysql.connector.connect(
#   host="localhost",
#   user="foorx",
#   passwd="Mav3r1ck!",
#   database="ml_logs"
# )
# mysqlCursor = conn.cursor(buffered=True)
# file = open(fileName, 'r')
# fileData = file.read()
# sql = "INSERT INTO trainingLogs(fileName, mse, trainingSetName, trainTestRatio, fileData, comments) VALUES (%s, %s, %s, %s, %s,%s)"
# values = (fileName, strFloat(MSE), trainingSetName, strFloat(trainPercentage), fileData, comments)
# mysqlCursor.execute(sql, values)
# conn.commit()