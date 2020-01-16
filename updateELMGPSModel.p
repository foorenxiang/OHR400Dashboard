import sys
import numpy as np
import pandas as pd
from joblib import dump, load  #model persistance library
import mysql.connector

########ELM Dependencies########
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression

from elm import ELMClassifier
from random_hidden_layer import RBFRandomHiddenLayer
from random_hidden_layer import SimpleRandomHiddenLayer
########ELM Dependencies########

pd.set_option('display.max_rows', None)
#fallback csv training data if not using kdb data (for testing purposes)
csvTrainingData = 'trainingDataAbove100kph.csv'

#mysql update setup variables
#cannot use __file__ when running in KDB+
fileName = 'updateELModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'ELM using '

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

trainX = trainingDataTrain.copy()
trainX.drop(['GPSspeedkph'], axis=1, inplace = True)
###APPLYING NORMALISATION TO DATASET AS REQUIRED BY ELM
trainX = StandardScaler().fit_transform(trainX)
trainy = trainingDataTrain["GPSspeedkph"]
trainy = trainy.astype('int')
# Index(['timeDeltaus', 'currentSampleHz', 'timeus', 'rcCommand0', 'rcCommand1',
       # 'rcCommand2', 'rcCommand3', 'vbatLatestV', 'gyroADC0', 'gyroADC1',
       # 'gyroADC2', 'accSmooth0', 'accSmooth1', 'accSmooth2', 'motor0',
       # 'motor1', 'motor2', 'motor3'],
      # dtype='object')

testX = trainingDataTest.copy()
testX.drop(['GPSspeedkph'], axis=1, inplace = True)
###APPLYING NORMALISATION TO DATASET AS REQUIRED BY ELM
testX = StandardScaler().fit_transform(testX)
testy = trainingDataTest["GPSspeedkph"]

#########from plot_elm_comparison.p#########
kernel_names = ["tanh", "tribas", "hardlim", "rbf(0.1)"]
model_names = list(map(lambda name: name+"GPSSpeedModel", kernel_names))
nh = 10

# pass user defined transfer func
sinsq = (lambda x: np.power(np.sin(x), 2.0))
srhl_sinsq = SimpleRandomHiddenLayer(n_hidden=nh,
                                     activation_func=sinsq,
                                     random_state=0)

# use internal transfer funcs
srhl_tanh = SimpleRandomHiddenLayer(n_hidden=nh,
                                    activation_func='tanh',
                                    random_state=0)

srhl_tribas = SimpleRandomHiddenLayer(n_hidden=nh,
                                      activation_func='tribas',
                                      random_state=0)

srhl_hardlim = SimpleRandomHiddenLayer(n_hidden=nh,
                                       activation_func='hardlim',
                                       random_state=0)

# use gaussian RBF
srhl_rbf = RBFRandomHiddenLayer(n_hidden=nh*2, gamma=0.1, random_state=0)

log_reg = LogisticRegression(solver='liblinear')

classifiers = [ELMClassifier(srhl_tanh), ELMClassifier(srhl_tribas),ELMClassifier(srhl_hardlim),ELMClassifier(srhl_rbf)]
#########from plot_elm_comparison.p#########

#########only fit rbf kernel#########

model = ELMClassifier(srhl_rbf)
model.fit(trainX, trainy)

savedGPSSpeedModel = dump(model, 'elmGPSSpeedModel.joblib')
#########only fit rbf kernel#########

#########fit all elm kernels#########
#ELM(10,tanh,LR) and ELM(10,sinsq) transfer functions are not compatible
maxHiddenLayers = 20

#iterate through different numbers of hidden layers
allTrainedELMModels = dict()
maxHiddenLayers = range(1, 1 + maxHiddenLayers)
for i in maxHiddenLayers:
	print("Number of hidden layers: " + str(i) + "\n")
	nh = i
	TrainedELMModels = dict()
	#iterate through each kernel
	for modeltype, model_name, kernel_name in zip(classifiers,model_names,kernel_names):
		print("Training kernel: " + kernel_name)
		model = modeltype
		model.fit(trainX, trainy)
		savedGPSSpeedModel = dump(model, model_name) #save trained model to disk
		TrainedELMModels[kernel_name] = model #add trained model to allTrainedELMModels dictionary

	allTrainedELMModels[i] = TrainedELMModels #save models from current iteration of hidden layers

	print("\n")
#########fit all elm kernels#########

model = 0 # erase model from memory


#########test rbf kernel#########
# print("Testing ELM RBF Kernel")
# #test model
# model = load('elmGPSSpeedModel.joblib')
# # print(testX.columns)
# y_pred= model.predict(testX)

# #calculate mean square error
# MSE = mse(y_pred,testy)

# #display mean square error
# # print("Actual vs Predictions:")
# # testy = testy.to_numpy()
# # for i in range(len(y_pred)):
# # 	print(strFloat(testy[i]) + " || " + strFloat(y_pred[i]))
# print("Mean Square Error:")
# print(strFloat(MSE))
#########test rbf kernel#########

#########test all ELM kernels#########
print("\nTesting all kernels...")
for i in maxHiddenLayers: 
	print("\nLayer: " + str(i))
	for kernel_name in kernel_names:
		print("Testing kernel: " + kernel_name)
		#test model
		model = allTrainedELMModels[i][kernel_name]
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
#########test all ELM kernels#########

#save model setup to mysql db
# conn = mysql.connector.connect(host="localhost", user="foorx", passwd="Mav3r1ck!", database="ml_logs")
# mysqlCursor = conn.cursor(buffered=True)
# file = open(fileName, 'r')
# fileData = file.read()
# sql = "INSERT INTO trainingLogs(fileName, mse, trainingSetName, trainTestRatio, fileData, comments) VALUES (%s, %s, %s, %s, %s,%s)"
# values = (fileName, strFloat(MSE), trainingSetName, strFloat(trainPercentage), fileData, comments)
# mysqlCursor.execute(sql, values)
# conn.commit()