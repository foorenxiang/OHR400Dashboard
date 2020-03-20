import sys
import numpy as np
import pandas as pd
import sklearn.gaussian_process as gp
from sklearn.decomposition import PCA
from joblib import dump, load  #model persistance library
import matplotlib.pyplot as plt
import mysql.connector

pd.set_option('display.max_rows', None)
#fallback csv training data if not using kdb data (for testing purposes)
csvTrainingData = 'trainingDataAbove100kph.csv'

#mysql update setup variables
#cannot use __file__ when running in KDB+
fileName = 'updateGPRGPSModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Training multiple GPR kernel'
print(comments)

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
			print("principalComponents")
			print(pcaModel.components_)
		trainX = pd.DataFrame(pcaModel.transform(trainX))
		testX = pd.DataFrame(pcaModel.transform(testX))
		print(trainX)
	else:
		print("Not using PCA!")
######if using PCA, determine principal components######


#using constant gpr kernel
# kernel = gp.kernels.ConstantKernel() * gp.kernels.RBF()
kernel = gp.kernels.RationalQuadratic()
kernels = [gp.kernels.ConstantKernel(), gp.kernels.RBF(), gp.kernels.Matern(), gp.kernels.RationalQuadratic()] #gp.kernels.ExpSineSquared(), gp.kernels.DotProduct()
kernelNames = ["ConstantKernel", "RBF", "Matern", "RationalQuadratic"]

#generate convoluted kernels
convolutedKernels = []
convolutedKernelNames = []
for i in range(0, len(kernels)-1):
	for j in range(i+1, len(kernels)):
		convolutedKernels.append(kernels[i]*kernels[j])
		convolutedKernelNames.append(kernelNames[i]+ "*" + kernelNames[j])

print("number of convolutedKernels: " + str(len(convolutedKernels)))
bestModel = None
bestMSE = None
bestRMSE = None
RMSEs = []
# +convolutedKernels
for kernel, kernelName in zip(kernels+convolutedKernels, kernelNames + convolutedKernelNames):
	# print("GPR Kernel used:")
	# print(kernel)

	# model = gp.GaussianProcessRegressor(kernel=gp.kernels.RationalQuadratic(), n_restarts_optimizer=10, alpha=0.001, normalize_y=True)
	model = gp.GaussianProcessRegressor(kernel=kernel, alpha=0.001, normalize_y=True)

	model.fit(trainX, trainy)

	savedGPSSpeedModelGPR = dump(model, 'gprGPSSpeedModel.joblib')

	#test model
	y_pred= model.predict(testX)

	#calculate mean square error
	MSE = mse(y_pred,testy)
	RMSE = MSE**0.5
	RMSEs.append(RMSE)

	if bestModel == None:
		bestModel = model
		bestKernel = kernelName
		bestMSE = MSE
		bestRMSE = RMSE
	elif RMSE < bestRMSE*0.95:
		bestModel = model
		bestKernel = kernelName
		bestMSE = MSE
		bestRMSE = RMSE

	print("MSE:")
	print(strFloat(MSE))
	print("RMSE:")
	print(strFloat(RMSE) + "\n")

print("Optimal kernel found!: " + bestKernel)
print("bestMSE")
print(bestMSE)
print("bestRMSE:")
print(bestRMSE)

if kdbSource == False:
	fig = plt.figure()
	ax = fig.add_subplot(111)
	ax.set(ylim=(0, 100))
	plotTitle = "Gaussian Process Regression GPS"
	if usePCA:
		plotTitle += " PCA"
	else:
		plotTitle += " no PCA"
	plotTitle += " RMSE: " + strFloat(RMSE) + " (" + bestKernel + ")"
	plt.title(plotTitle)
	plt.ylabel('RMSE')
	x = range(0, len(RMSEs))
	plt.xticks(ticks=x, labels=kernelNames + convolutedKernelNames, rotation=20)
	ax.scatter(x, RMSEs, s=10, c='b', marker="s")
	figureName = "GPR GPS"
	if usePCA:
		figureName += " PCA"
	else:
		figureName += " no PCA"
	fileExt = ".png"
	plt.savefig(figureName + fileExt)
	plt.show()

#save model setup to mysql db
conn = mysql.connector.connect(host="localhost", user="foorx", passwd="Mav3r1ck!", database="ml_logs")
mysqlCursor = conn.cursor(buffered=True)
file = open(fileName, 'r')
fileData = file.read()
sql = "INSERT INTO trainingLogs(fileName, mse, trainingSetName, trainTestRatio, fileData, comments) VALUES (%s, %s, %s, %s, %s,%s)"
values = (fileName, strFloat(MSE), trainingSetName, strFloat(trainPercentage), fileData, comments)
mysqlCursor.execute(sql, values)
conn.commit()