import sys
import numpy as np
import pandas as pd
import sklearn.gaussian_process as gp
from joblib import dump, load  #model persistance library
import mysql.connector

pd.set_option('display.max_rows', None)
#fallback csv training data if not using kdb data (for testing purposes)
csvTrainingData = 'trainingDataAbove100kph.csv'

#mysql update setup variables
#cannot use __file__ when running in KDB+
fileName = 'updateGPRLiPoModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Using RationalQuadratic GPR kernel'

def mse(pred, actual):
	return ((pred-actual)**2).mean()


def strFloat(floatVal):
	return "{0:.2f}".format(round(floatVal,2))

if 'trainingDataPDF' not in globals():
	trainingDataPDF = pd.read_csv(csvTrainingData)
	print("Training using csv input!")

#using else or try catch causes bugs with embedpy
if 'trainingDataPDF' in globals():
	trainingSetName = "KDB+ Input"
	print("Training using KDB+ input!")

trainPercentage = 0.7
trainingDataTrain = trainingDataPDF[:int(trainPercentage*len(trainingDataPDF))]
trainingDataTest = trainingDataPDF[int(trainPercentage*len(trainingDataPDF)):]
# trainX <-- training observations [# points, # features]
# trainy <-- training labels [# points]
# testX <-- test observations [# points, # features]
# testy <-- test labels [# points]

trainX = trainingDataTrain.drop(['vbatLatestV'], axis=1, inplace = False)
trainy = trainingDataTrain["vbatLatestV"]
# Index(['timeDeltaus', 'currentSampleHz', 'timeus', 'rcCommand0', 'rcCommand1',
       # 'rcCommand2', 'rcCommand3', 'vbatLatestV', 'gyroADC0', 'gyroADC1',
       # 'gyroADC2', 'accSmooth0', 'accSmooth1', 'accSmooth2', 'motor0',
       # 'motor1', 'motor2', 'motor3'],
      # dtype='object')

testX = trainingDataTest.drop(['vbatLatestV'], axis=1, inplace = False)
testy = trainingDataTest["vbatLatestV"]

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

savedLiPoModelGPR = dump(model, 'gprLiPoModel.joblib')

model = 0 

#test model
model = load('gprLiPoModel.joblib')
# print(testX.columns)
y_pred= model.predict(testX)

#calculate mean square error
MSE = mse(y_pred,testy)

#display mean square error
# print("Actual vs Predictions:")
# testy = testy.to_numpy()
# for i in range(len(y_pred)):
# 	print(strFloat(testy[i]) + " || " + strFloat(y_pred[i]))
print("Mean Square Error:")
print(strFloat(MSE))