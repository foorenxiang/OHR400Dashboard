# LSTM for international airline passengers problem with memory
import numpy as np
import matplotlib.pyplot as plt
# from pandas import read_csv
import pandas as pd
import math
from keras.models import Sequential
from keras.layers import Dense
from keras.layers import LSTM
from sklearn.preprocessing import MinMaxScaler, StandardScaler
from joblib import dump, load  #model persistance library
import mysql.connector


# from sklearn.metrics import mean_squared_error
	# # convert an array of values into a dataset matrix
	# def create_dataset(dataset, look_back=1):
	# 	dataX, dataY = [], []
	# 	for i in range(len(dataset)-look_back-1):
	# 		a = dataset[i:(i+look_back), 0]
	# 		dataX.append(a)
	# 		dataY.append(dataset[i + look_back, 0])
	# 	return numpy.array(dataX), numpy.array(dataY)
	# # fix random seed for reproducibility
	# numpy.random.seed(7)
	# # load the dataset
	# dataframe = read_csv('airline-passengers.csv', usecols=[1], engine='python')
	# dataset = dataframe.values
	# dataset = dataset.astype('float32')
	# # normalize the dataset
	# scaler = MinMaxScaler(feature_range=(0, 1))
	# dataset = scaler.fit_transform(dataset)

pd.set_option('display.max_rows', None)
#fallback csv training data if not using kdb data (for testing purposes)
csvTrainingData = 'LSTMTrainingData.csv'

#mysql update setup variables
#cannot use __file__ when running in KDB+
fileName = 'updateMemoryLSTM.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Using Memory LSTM'

def mse(pred, actual):
	return ((pred-actual)**2).mean()


def strFloat(floatVal):
	return "{0:.2f}".format(round(floatVal,2))

kdbSource = True

if 'trainingDataPDF' not in globals():
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
# label is rcCommand3, the throttle input
trainX = trainingDataTrain.copy()
trainX.drop(['expectedThrottle'], axis=1, inplace = True)

#####APPLYING NORMALISATION TO DATASET#####
trainXStandardScalar = StandardScaler()
yStandardScalar = StandardScaler()
trainX = trainXStandardScalar.fit_transform(trainX)
trainy = trainingDataTrain['expectedThrottle'].to_frame()
trainy = yStandardScalar.fit_transform(trainy)

testX = trainingDataTest.copy()
testX.drop(['expectedThrottle'], axis=1, inplace = True)
testXStandardScalar = StandardScaler()
testX = testXStandardScalar.fit_transform(testX)
testy = trainingDataTest['expectedThrottle'].to_frame()

# train the LSTM model
if not 'lookbackSteps' in globals():
	lookbackSteps = 3

#reshape trainX for LSTM input
trainX = (trainX, (trainX.shape[0], lookbackSteps, trainX.shape[1]))
testX = (testX, (testX.shape[0], lookbackSteps, testX.shape[1]))

batchSize = 1
model = Sequential()
trainingEpochs = 100
model.add(LSTM(4, input_shape=(1, lookbackSteps)))
model.add(Dense(1))
model.compile(loss='mean_squared_error', optimizer='adam')
for _ in range(trainingEpochs):
	model.fit(trainX, trainy, epochs=1, batch_size=batchSize, verbose=2)

# save trained model to disk
savedMemoryLSTMModel = dump(model, 'MemoryLSTMModel.joblib')

	# # split into train and test sets
	# train_size = int(len(dataset) * 0.67)
	# test_size = len(dataset) - train_size
	# train, test = dataset[0:train_size,:], dataset[train_size:len(dataset),:]
	# # reshape into X=t and Y=t+1
	# look_back = 3
	# trainX, trainY = create_dataset(train, look_back)
	# testX, testY = create_dataset(test, look_back)
	# # reshape input to be [samples, time steps, features]
	# trainX = numpy.reshape(trainX, (trainX.shape[0], trainX.shape[1], 1))
	# testX = numpy.reshape(testX, (testX.shape[0], testX.shape[1], 1))
	# create and fit the LSTM network
	# batch_size = 1
	# model = Sequential()
	# model.add(LSTM(4, batch_input_shape=(batch_size, look_back, 1), stateful=True))
	# model.add(Dense(1))
	# model.compile(loss='mean_squared_error', optimizer='adam')
	# for i in range(100):
	# 	model.fit(trainX, trainY, epochs=1, batch_size=batch_size, verbose=2, shuffle=False)
	# 	model.reset_states()
	# make predictions
# trainyPred = model.predict(trainX, batch_size=batchSize)
# trainyPred = yStandardScalar.inverse_transform(trainyPred)

yPred = model.predict(testX, batch_size=batchSize)
yPred = yStandardScalar.inverse_transform(trainyPred)

MSE = mse(yPred,np.asarray(testy))
RMSE = MSE**0.5

	# invert predictions
	# trainPredict = scaler.inverse_transform(trainPredict)
	# trainY = scaler.inverse_transform([trainY])
	# testPredict = scaler.inverse_transform(testPredict)
	# testY = scaler.inverse_transform([testY])
# calculate root mean squared error
	# trainScore = math.sqrt(mean_squared_error(trainY[0], trainPredict[:,0]))
	# print('Train Score: %.2f RMSE' % (trainScore))
	# testScore = math.sqrt(mean_squared_error(testY[0], testPredict[:,0]))
	# print('Test Score: %.2f RMSE' % (testScore))
	# # shift train predictions for plotting
	# trainPredictPlot = numpy.empty_like(dataset)
	# trainPredictPlot[:, :] = numpy.nan
	# trainPredictPlot[look_back:len(trainPredict)+look_back, :] = trainPredict
	# # shift test predictions for plotting
	# testPredictPlot = numpy.empty_like(dataset)
	# testPredictPlot[:, :] = numpy.nan
	# testPredictPlot[len(trainPredict)+(look_back*2)+1:len(dataset)-1, :] = testPredict
	# # plot baseline and predictions
	# plt.plot(scaler.inverse_transform(dataset))
	# plt.plot(trainPredictPlot)
	# plt.plot(testPredictPlot)
	# plt.show()

# if kdbSource == False:
# 	fig = plt.figure()
# 	ax = fig.add_subplot(111)
# 	ax.set(ylim=(0, 100))
# 	plotTitle = "Memory LSTM"
# 	plotTitle += " RMSE: " + strFloat(RMSE)
# 	plt.title(plotTitle)
# 	plt.ylabel('RMSE')
# 	x = range(0, len(models))
# 	plt.xticks(ticks=x, labels=modelNames, rotation=20)
# 	ax.scatter(x,RMSEs, s=10, c='b', marker="s")
# 	figureName = "GradBoost GPS"
# 	if usePCA:
# 		figureName += " PCA"
# 	else:
# 		figureName += " no PCA"
# 	fileExt = ".png"
# 	plt.savefig(figureName + fileExt)
# 	plt.show()

#save model setup to mysql db
conn = mysql.connector.connect(host="localhost", user="foorx", passwd="Mav3r1ck!", database="ml_logs")
mysqlCursor = conn.cursor(buffered=True)
file = open(fileName, 'r')
fileData = file.read()
sql = "INSERT INTO trainingLogs(fileName, mse, trainingSetName, trainTestRatio, fileData, comments) VALUES (%s, %s, %s, %s, %s,%s)"
values = (fileName, strFloat(MSE), trainingSetName, strFloat(trainPercentage), fileData, comments)
mysqlCursor.execute(sql, values)
conn.commit()