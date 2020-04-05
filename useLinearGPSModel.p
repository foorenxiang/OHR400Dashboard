import sys #system
import numpy as np #numpy
import pandas as pd #pandas
from sklearn.preprocessing import StandardScaler #normalisation library
from sklearn import linear_model as lm #linear model library
from joblib import dump, load  #model persistance library

#model deployment:
#load saved model from disk
gpsSpeedLReg = load('./models/gpsSpeedLReg.model')

def predictGPSSpeed(inputFrame):
	return gpsSpeedLReg.predict(inputFrame)

#inputPDF is inserted into program space by KDB
inputPDF.drop(['GPSspeedkph'], axis=1, inplace = True)
scale = StandardScaler() #create scaler object
inputPDF = scale.fit_transform(inputPDF) #normalise dataset

#get predictions from model deployed model
gpsSpeedPredictions = predictGPSSpeed(inputPDF)

print("Number of predictions: " + str(len(gpsSpeedPredictions)))

print("Predictions:")
for x in gpsSpeedPredictions:
	print("{0:.2f}".format(x) + 'kph')