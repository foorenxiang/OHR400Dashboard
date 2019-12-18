import pandas as pd
import sklearn.gaussian_process as gp
from joblib import dump, load  #model persistance library
import mysql.connector

#mysql update setup variables
fileName = 'gprLiPoModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Using RationalQuadratic GPR kernel'

def mse(pred, actual):
	return ((pred-actual)**2).mean()


def strFloat(floatVal):
	return "{0:.2f}".format(round(floatVal,2))


trainingDataPDF = pd.read_csv('trainingDataAbove100kph.csv') #comment out if importing data from kdb
# trainingDataPDF = pd.read_csv('trainingData.csv') #comment out if importing data from kdb
trainPercentage = 0.6
trainingDataTrain = trainingDataPDF[:int(trainPercentage*len(trainingDataPDF))]
trainingDataTest = trainingDataPDF[int(trainPercentage*len(trainingDataPDF)):]
inputPDF = trainingDataTest #comment out if importing data from kdb

predictionVariable = 'vbatLatestV'

trainX = trainingDataTrain.copy()
print(trainX)
trainX.drop([predictionVariable], axis=1, inplace = True)
trainX.drop(['timeDeltaus'], axis=1, inplace = True)
trainX.drop(['timeus'], axis=1, inplace = True)
trainy = trainingDataTrain[predictionVariable]


testX = trainingDataTest.copy()
testX.drop([predictionVariable], axis=1, inplace = True)
testX.drop(['timeDeltaus'], axis=1, inplace = True)
testX.drop(['timeus'], axis=1, inplace = True)
testy = trainingDataTest[predictionVariable]


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

y_pred, covMatrix = model.predict(testX, return_cov=True)

MSE = mse(y_pred,testy)
print("Actual vs Predictions:")
testy = testy.to_numpy()

for i in range(len(y_pred)):
	print(strFloat(testy[i]) + " || " + strFloat(y_pred[i]))
print("Mean Square Error:")
print(strFloat(MSE))

conn = mysql.connector.connect(
  host="localhost",
  user="foorx",
  passwd="Mav3r1ck!",
  database="ml_logs"
)
mysqlCursor = conn.cursor(buffered=True)
file = open(fileName, 'r')
fileData = file.read()
sql = "INSERT INTO trainingLogs(fileName, mse, trainingSetName, trainTestRatio, fileData, comments) VALUES (%s, %s, %s, %s, %s,%s)"
values = (fileName, strFloat(MSE), trainingSetName, strFloat(trainPercentage), fileData, comments)
mysqlCursor.execute(sql, values)
conn.commit()