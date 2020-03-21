######Reference Material Used######
#https://machinelearningmastery.com/time-series-prediction-lstm-recurrent-neural-networks-python-keras/
######Reference Material Used######


# LSTM for international airline passengers problem with time step regression framing
import numpy
import matplotlib.pyplot as plt
# from pandas import read_csv
import math
from keras.models import Sequential
from keras.layers import Dense
from keras.layers import LSTM
from sklearn.preprocessing import MinMaxScaler, StandardScaler
from sklearn.metrics import mean_squared_error

# convert an array of values into a dataset matrix
def create_dataset(dataset, look_back=1):
	dataX, dataY = [], []
	for i in range(len(dataset)-look_back-1):
		a = dataset[i:(i+look_back), 0]
		dataX.append(a)
		dataY.append(dataset[i + look_back, 0])
	return numpy.array(dataX), numpy.array(dataY)
# fix random seed for reproducibility
numpy.random.seed(7)
# load the dataset
dataframe = read_csv('airline-passengers.csv', usecols=[1], engine='python')
dataset = dataframe.values
dataset = dataset.astype('float32')
# normalize the dataset
scaler = MinMaxScaler(feature_range=(0, 1))
dataset = scaler.fit_transform(dataset)1
# split into train and test sets
train_size = int(len(dataset) * 0.67)
test_size = len(dataset) - train_size
train, test = dataset[0:train_size,:], dataset[train_size:len(dataset),:]
# reshape into X=t and Y=t+1
look_back = 3
trainX, trainY = create_dataset(train, look_back)
testX, testY = create_dataset(test, look_back)
# reshape input to be [samples, time steps, features]
trainX = numpy.reshape(trainX, (trainX.shape[0], trainX.shape[1], 1))
testX = numpy.reshape(testX, (testX.shape[0], testX.shape[1], 1))
# create and fit the LSTM network
model = Sequential()
model.add(LSTM(4, input_shape=(look_back, 1)))
model.add(Dense(1))
model.compile(loss='mean_squared_error', optimizer='adam')
model.fit(trainX, trainY, epochs=100, batch_size=1, verbose=2)
# make predictions
trainPredict = model.predict(trainX)
testPredict = model.predict(testX)
# invert predictions
trainPredict = scaler.inverse_transform(trainPredict)
trainY = scaler.inverse_transform([trainY])
testPredict = scaler.inverse_transform(testPredict)
testY = scaler.inverse_transform([testY])
# calculate root mean squared error
trainScore = math.sqrt(mean_squared_error(trainY[0], trainPredict[:,0]))
print('Train Score: %.2f RMSE' % (trainScore))
testScore = math.sqrt(mean_squared_error(testY[0], testPredict[:,0]))
print('Test Score: %.2f RMSE' % (testScore))
# shift train predictions for plotting
trainPredictPlot = numpy.empty_like(dataset)
trainPredictPlot[:, :] = numpy.nan
trainPredictPlot[look_back:len(trainPredict)+look_back, :] = trainPredict
# shift test predictions for plotting
testPredictPlot = numpy.empty_like(dataset)
testPredictPlot[:, :] = numpy.nan
testPredictPlot[len(trainPredict)+(look_back*2)+1:len(dataset)-1, :] = testPredict
# plot baseline and predictions
plt.plot(scaler.inverse_transform(dataset))
plt.plot(trainPredictPlot)
plt.plot(testPredictPlot)
plt.show()






import sys
import numpy as np
import pandas as pd
from joblib import dump, load  #model persistance librny
#from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
import matplotlib.pyplot as plt
import mysql.connector

pd.set_option('display.max_rows', None)
#fallback csv training data if not using kdb data (for testing purposes)
csvTrainingData = 'trainingDataAbove100kph.csv'

#mysql update setup variables
#cannot use __file__ when running in KDB+
fileName = 'updateLSTM.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'LSTM'

def mse(pred, actual):
	return ((pred-actual)**2).mean()

def rmse():
	mse**0.5

def strFloat(floatVal):
	return "{0:.2f}".format(round(floatVal,2))

kdbSource = True

if 'LSTMtrainingDataPDF' not in globals():
	kdbSource = False
	trainingDataPDF = pd.read_csv(csvTrainingData)
	print("Training using csv input!")

#using else or try catch causes bugs with embedpy
if kdbSource:
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

#####APPLYING NORMALISATION TO DATASET AS REQUIRED BY ELM#####
trainXStandardScalar = StandardScaler()
trainyStandardScalar = StandardScaler()
trainX = trainXStandardScalar.fit_transform(trainX)
trainy = trainingDataTrain["GPSspeedkph"].to_frame()
trainy = trainyStandardScalar.fit_transform(trainy)
# Index(['timeDeltaus', 'currentSampleHz', 'timeus', 'rcCommand0', 'rcCommand1',
       # 'rcCommand2', 'rcCommand3', 'vbatLatestV', 'gyroADC0', 'gyroADC1',
       # 'gyroADC2', 'accSmooth0', 'accSmooth1', 'accSmooth2', 'motor0',
       # 'motor1', 'motor2', 'motor3'],
      # dtype='object')

testX = trainingDataTest.copy()
testX.drop(['GPSspeedkph'], axis=1, inplace = True)
testXStandardScalar = StandardScaler()
testX = testXStandardScalar.fit_transform(testX)
testy = trainingDataTest["GPSspeedkph"].to_frame()
#####APPLYING NORMALISATION TO DATASET AS REQUIRED BY ELM#####

######if using PCA, determine principal components######
usePCA = False
covarianceExplanation = 0.95
if 'usePCA' in globals():
	if usePCA:
		print("Using PCA!")
		if 'pcaModel' not in globals():
			if 'covarianceExplanation' not in globals():
				covarianceExplanation = 1
			pcaModel = PCA(n_components=covarianceExplanation)
			pcaModel.fit(trainX)
			principalComponents = pcaModel.components_
			print("principalComponents:")
			print(principalComponents)
		reducedDimTrainX = pd.DataFrame(pcaModel.transform(trainX))
		reducedDimTestX = pd.DataFrame(pcaModel.transform(testX))
else:
	print("Not using PCA!")
######if using PCA, determine principal components######

######LSTM Setup######
inputMinMaxScalar = MinMaxScalar(feature_range=(-1,1))
scaledInput = inputMinMaxScalar.fit_transform()