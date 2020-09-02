# reference used: from https://machinelearningmastery.com/time-series-prediction-lstm-recurrent-neural-networks-python-keras/
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import math
from keras.models import Sequential
from keras.layers import Dense
from keras.layers import LSTM
from sklearn.preprocessing import MinMaxScaler, StandardScaler
from joblib import dump, load  # model persistance library
import mysql.connector
import sys

pd.set_option('display.max_rows', None)

# mysql update setup variables
# cannot use __file__ when running in KDB+
fileName = 'updateRegressionWindowLSTM.p'
trainingFile = 'synthesizedThrottleLSTMTrainingDataMatrix'
trainingSetName = trainingFile + '.joblib'
comments = 'Using Regression (Window) LSTM'


def mse(pred, actual):
    return ((pred-actual)**2).mean()


def strFloat(floatVal):
    return "{0:.2f}".format(round(floatVal, 2))


kdbSource = True

if 'trainingDataPDF' not in globals():
    kdbSource = False
    trainingDataPDF = load(trainingFile + '.joblib')
    print("Training using LSTM training data on disk!")

# using else or try catch causes bugs with embedpy
if kdbSource:
    trainingSetName = "KDB+ Input"
    print("Training using KDB+ input!")

trainPercentage = 0.8
trainingDataTrain = trainingDataPDF[:int(trainPercentage*len(trainingDataPDF))]
trainingDataTest = trainingDataPDF[int(trainPercentage*len(trainingDataPDF)):]

# trainX <-- training observations [# points, # features]
# trainy <-- training labels [# points]
# testX <-- test observations [# points, # features]
# testy <-- test labels [# points]
# label is rcCommand3, the throttle input
trainX = trainingDataTrain.drop(
    trainingDataTrain.columns[-1], axis=1, inplace=False)
# get expected throttle column
trainy = trainingDataTrain.iloc[:, -1].to_frame()
testX = trainingDataTest.drop(
    trainingDataTest.columns[-1], axis=1, inplace=False)
testy = trainingDataTest.iloc[:, -1].to_frame()  # get expected throttle column

#####APPLYING NORMALISATION TO DATASET#####
# Normalisation already done in kdb processed data!!!
# if not using standard scaler, must cast to numpy array
trainX = trainX.to_numpy()
trainy = trainy.to_numpy()
testX = testX.to_numpy()
testy = testy.to_numpy()

# train the LSTM models
# calculate lookbacksteps from features in training dataframe
lookbackSteps = trainingDataPDF.shape[1]-1
print("Look back steps detected: " + str(lookbackSteps))


# reshape trainX for LSTM input
trainX = np.reshape(trainX, (trainX.shape[0], 1, trainX.shape[1]))
testX = np.reshape(testX, (testX.shape[0], 1, testX.shape[1]))

batchSize = 1
model = Sequential()
trainingEpochs = 100
model.add(LSTM(4, input_shape=(1, lookbackSteps)))
model.add(Dense(1))
model.compile(loss='mean_squared_error', optimizer='adam')
model.fit(trainX, trainy, epochs=trainingEpochs,
          batch_size=batchSize, verbose=2)

# save trained model to disk
modelSave = {}
modelSave["model"] = model
modelSave["batchSize"] = batchSize
modelSave["lookbackSteps"] = lookbackSteps
dump(modelSave, './models/RegressionWindowLSTMModel.model')

# load trained model from disk for verification
modelSave = load('./models/RegressionWindowLSTMModel.model')
model = modelSave["model"]
batchSize = modelSave["batchSize"]
lookbackSteps = modelSave["lookbackSteps"]

trainyPred = model.predict(trainX, batch_size=batchSize)
# transform back to throttle range [1000,2000]
trainyPred = ((trainyPred*1000)+1000).astype('int')

yPred = model.predict(testX, batch_size=batchSize)
# transform back to throttle range [1000,2000]
yPred = ((yPred*1000)+1000).astype('int')

MSE = mse(yPred, np.asarray(testy))
RMSE = MSE**0.5

# if not using KDB, display plot
if kdbSource == False:
    # plot and save training result to disk
    from pandas import read_csv
    dataframe = read_csv(
        trainingFile[:-len("Matrix")] + ".csv", usecols=[1], engine='python')
    dataset = dataframe.values
    dataset = dataset.astype('float32')
    trainyPredPlot = np.empty_like(dataset)
    trainyPredPlot[:, :] = np.nan
    trainyPredPlot[lookbackSteps:len(trainyPred)+lookbackSteps, :] = trainyPred
    fig = plt.figure()
    plotTitle = "Regression (Normal) LSTM"
    plotTitle += " RMSE: " + strFloat(RMSE)
    plt.title(plotTitle)
    plt.ylabel('Throttle Values')
    plt.xlabel('Time Steps')
    plt.plot(dataset)
    plt.plot(trainyPredPlot)
    figureName = "Regression Normal LSTM"
    fileExt = ".png"
    plt.savefig(figureName + fileExt)
    plt.show()

print("Finished training Regression (Normal) LSTM!")
