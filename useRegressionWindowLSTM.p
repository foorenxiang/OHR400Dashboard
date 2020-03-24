# LSTM for international airline passengers problem with memory
import numpy as np
import pandas as pd
import math
from keras.models import Sequential
from keras.layers import Dense
from keras.layers import LSTM
from sklearn.preprocessing import StandardScaler
from joblib import load

pd.set_option('display.max_rows', None)

comments = 'Using Regression (Normal) LSTM'
print(comments)

def mse(pred, actual):
	return ((pred-actual)**2).mean()


def strFloat(floatVal):
	return "{0:.2f}".format(round(floatVal,2))

modelSave = load('MemoryLSTMModel.joblib')
model = modelSave["model"]
yStandardScalar = modelSave["yStandardScalar"]
batchSize = modelSave["batchSize"]
lookbackSteps = modelSave["lookbackSteps"]

kdbSource = True

if 'inputPDF' not in globals():
	kdbSource = False
	inputPDF = load('synthesizedThrottleLSTMTrainingDataMatrix.joblib')
	print("Testing using LSTM training data on disk!")

#using else or try catch causes bugs with embedpy
if kdbSource:
	print("Predicting throttle using KDB+ input!")

X = inputPDF.drop(inputPDF.columns[-1], axis=1, inplace = False)
y = inputPDF.iloc[:,-1].to_frame() # 
#####APPLYING NORMALISATION TO DATASET#####
XStandardScalar = StandardScaler()
X = XStandardScalar.fit_transform(X)

# train the LSTM models
lookbackStepsCheck = inputPDF.shape[1]-1 # calculate lookbacksteps from features in training dataframe 
print("Look back steps detected: " + str(lookbackSteps))

assert (lookbackSteps==lookbackStepsCheck), "Mismatch of lookback steps between datastream and model! Wrong model file loaded?"

#reshape X for LSTM input
X = np.reshape(X, (X.shape[0], 1, X.shape[1]))

yPred = model.predict(X, batch_size=batchSize)
yPred = yStandardScalar.inverse_transform(yPred)

print("yPred Throttle predictions set!")