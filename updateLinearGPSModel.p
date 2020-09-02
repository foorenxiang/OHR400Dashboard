import sys  # system
import numpy as np  # numpy
import pandas as pd  # pandas
from sklearn.preprocessing import StandardScaler  # normalisation library
from sklearn import linear_model as lm  # linear model library
from joblib import dump, load  # model persistance library

# define functions


def mse(pred, actual):
    return ((pred-actual)**2).mean()


def strFloat(floatVal):
    return "{0:.2f}".format(round(floatVal, 2))


trainingDataPDF = pd.read_csv('trainingDataAbove100kph.csv')
print("trainingDataPDF columns:")
print(trainingDataPDF.columns)
trainPercentage = 0.75
trainingDataTrain = trainingDataPDF[:int(trainPercentage*len(trainingDataPDF))]
trainingDataTest = trainingDataPDF[int(trainPercentage*len(trainingDataPDF)):]
print("samples in trainingDataPDF: " + str(len(trainingDataPDF)))
print("samples in trainingDataTrain: " + str(len(trainingDataTrain)))
print("samples in trainingDataTest: " + str(len(trainingDataTest)))
# sys.exit(0)

# create dataframe with training inputs
gpsSpeedTrainX = trainingDataTrain.drop(['GPSspeedkph'], axis=1, inplace=False)
print("gpsSpeedTrainX: ")
# print(gpsSpeedX)
# for x in gpsSpeedTrainX.columns:
# print(x)

# create dataframe from test inputs
gpsSpeedTestX = trainingDataTest.drop(['GPSspeedkph'], axis=1, inplace=False)

# create series of labelled output
gpsSpeedy = trainingDataTrain["GPSspeedkph"]
print("gpsSpeedy: ")
print(gpsSpeedy)

# normalise training data
scale = StandardScaler()  # create scaler object
gpsSpeedTrainX = scale.fit_transform(gpsSpeedTrainX)

# normalise test data
gpsSpeedTestX = scale.fit_transform(gpsSpeedTestX)

# create linear regression model
gpsSpeedLReg = lm.LinearRegression()

# train linear regression model
gpsSpeedLReg.fit(gpsSpeedTrainX, gpsSpeedy)

# persist model
savedGPSSpeedModelLReg = dump(gpsSpeedLReg, './models/gpsSpeedLReg.model')
print("Saved model:")
print(savedGPSSpeedModelLReg)

# apply model to get prediction
gpsSpeedPredictions = gpsSpeedLReg.predict(gpsSpeedTestX)

# convert pandas series to numpy array
gpsSpeedTesty = trainingDataTest["GPSspeedkph"]
gpsSpeedTesty = gpsSpeedTesty.to_numpy()

# calculate error between prediction and actual result
# raw error
gpsSpeedError = (gpsSpeedPredictions - gpsSpeedTesty)

# print("GPS speed predictions: ")
# for x in gpsSpeedPredictions:
# 	print("{0:.2f}".format(x))
# print("\n")


# print("Actual gps speed:")
# for x in gpsSpeedTesty:
# 	print("{0:.2f}".format(x))
# print("\n")


# print("Raw errors:")
# for x in gpsSpeedError:
# 	print("{0:.2f}".format(x) + '%')
# print("\n")


# print("RMSE errors:")
# print(gpsSpeedRMSEError)
# print("\n")

# erase model in ram
gpsSpeedLReg = 0

# model deployment:
# load saved model from disk
gpsSpeedLReg = load('gpsSpeedLReg.model')


def predictGPSSpeed(inputFrame):
    return gpsSpeedLReg.predict(inputFrame)


# test deployed model
gpsSpeedPredictions = predictGPSSpeed(gpsSpeedTestX)

print("Actual vs Predictions:")
for i in range(len(gpsSpeedPredictions)):
    print(strFloat(gpsSpeedTesty[i]) + "kph || " +
          strFloat(gpsSpeedPredictions[i]) + "kph")

MSE = mse(gpsSpeedTesty, gpsSpeedPredictions)
RMSE = MSE**0.5
print("MSE:")
print(strFloat(MSE))
print("RMSE:")
print(strFloat(RMSE))
