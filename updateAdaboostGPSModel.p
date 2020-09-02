import sys
import math
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.neural_network import MLPRegressor
from sklearn.neighbors import KNeighborsRegressor
from sklearn.svm import SVR
from sklearn.gaussian_process import GaussianProcessRegressor
from sklearn.gaussian_process.kernels import RBF
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.ensemble import AdaBoostRegressor
from joblib import dump, load  # model persistance library
import matplotlib.pyplot as plt
import mysql.connector

pd.set_option('display.max_rows', None)
# fallback csv training data if not using kdb data (for testing purposes)
csvTrainingData = 'trainingDataAbove100kph.csv'

# mysql update setup variables
# cannot use __file__ when running in KDB+
fileName = 'updateGPRGPSModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Using Adaboost'
print(comments)


def mse(pred, actual):
    return ((pred-actual)**2).mean()


def strFloat(floatVal):
    return "{0:.2f}".format(round(floatVal, 2))


kdbSource = True

if 'trainingDataPDF' not in globals():
    kdbSource = False
    trainingDataPDF = pd.read_csv(csvTrainingData)
    print("Training using csv input!")

# using else or try catch causes bugs with embedpy
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

trainX = trainingDataTrain.drop(['GPSspeedkph'], axis=1, inplace=False)

#####APPLYING NORMALISATION TO DATASET#####
trainXStandardScalar = StandardScaler()
yStandardScalar = StandardScaler()
trainX = trainXStandardScalar.fit_transform(trainX)
trainy = trainingDataTrain["GPSspeedkph"].to_frame()
trainy = yStandardScalar.fit_transform(trainy)

testX = trainingDataTest.drop(['GPSspeedkph'], axis=1, inplace=False)
testXStandardScalar = StandardScaler()
testX = testXStandardScalar.fit_transform(testX)
testy = trainingDataTest["GPSspeedkph"].to_frame()
#####APPLYING NORMALISATION TO DATASET#####

######if using PCA, determine principal components######
usePCA = True
covarianceExplanation = 0.95
if 'usePCA' in globals():
    if usePCA:
        print("Using PCA!")
        if 'pcaModel' not in globals():
            if 'covarianceExplanation' not in globals():
                covarianceExplanation = 1
            pcaModel = PCA(n_components=covarianceExplanation)
            pcaModel.fit(trainX)
        trainX = pd.DataFrame(pcaModel.transform(trainX))
        testX = pd.DataFrame(pcaModel.transform(testX))
    else:
        print("Not using PCA!")
######if using PCA, determine principal components######

# baseEstimators = [None]
# baseEstimatorsNames = ['DecisionTreeRegressor(3)']

# , GaussianProcessRegressor(1.0 * RBF(1.0)), DecisionTreeRegressor(max_depth=5), RandomForestRegressor(max_depth=5, n_estimators=10, max_features=1), MLPRegressor(alpha=1, max_iter=1000)]
baseEstimators = [None, KNeighborsRegressor(3), SVR(
    kernel="linear", C=0.025), SVR(gamma=2, C=1)]


# , 'GaussianProcessRegressor(1.0 * RBF(1.0))', 'DecisionTreeRegressor(max_depth=5)', 'RandomForestRegressor(max_depth=5, n_estimators=10, max_features=1)', 'MLPRegressor(alpha=1, max_iter=1000)']
baseEstimatorsNames = [
    'DecisionTreeRegressor(3)', 'KNeighborsRegressor(3)', 'SVR(kernel="linear", C=0.025)', 'SVR(gamma=2, C=1)']

bestModel = None
bestMSE = None
bestRMSE = None
improvementPercentageThreshold = 0.05
RMSEs = []
models = []
modelNames = []
print("breakpoint")

for baseEstimator, baseEstimatorsName in zip(baseEstimators, baseEstimatorsNames):
    for treeDepth in range(4, 10):
        # test 10 estimator counts with exponential increase
        for n_estimator in np.logspace(start=math.log10(10), stop=math.log10(500), num=10):
            n_estimatorInt = int(n_estimator)
            print("Adaboost baseEstimator used:")
            baseEstimatorVariation = baseEstimatorsName
            baseEstimatorVariation += str(treeDepth)
            baseEstimatorVariation += " " + str(n_estimatorInt)
            print(baseEstimatorVariation)
            model = AdaBoostRegressor(
                base_estimator=baseEstimator, n_estimators=n_estimatorInt)

            model.fit(trainX, np.ravel(trainy))
            models.append(model)
            modelNames.append(baseEstimatorVariation)

            savedGPSSpeedModelSVR = dump(model, 'AdaboostGPSSpeedModel.joblib')
            y_pred = model.predict(testX)
            y_pred = yStandardScalar.inverse_transform(y_pred)

            # calculate mean square error
            MSE = mse(y_pred, np.asarray(testy))
            RMSE = MSE**0.5

            print("MSE:")
            print(strFloat(MSE))
            print("RMSE:")
            print(strFloat(RMSE)+"\n")
            RMSEs.append(RMSE)

            if bestMSE == None:
                bestMSE = MSE
                bestRMSE = RMSE
                bestModel = baseEstimatorVariation
            elif MSE < bestMSE*(1-improvementPercentageThreshold):
                bestMSE = MSE
                bestRMSE = RMSE
                bestModel = baseEstimatorVariation

print("Optimal model:")
print(bestModel)
print("Best MSE: " + str("{:.2f}".format(bestMSE)))
print("Best RMSE: " + str("{:.2f}".format(bestMSE**0.5)))

if kdbSource == False:
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.set(ylim=(0, 100))
    plotTitle = "Adaboost GPS"
    if usePCA:
        plotTitle += " PCA"
    else:
        plotTitle += " no PCA"
    plotTitle += " Best RMSE: " + strFloat(bestRMSE)
    plt.title(plotTitle)
    plt.ylabel('RMSE')
    x = range(0, len(models))
    plt.xticks(x, modelNames)
    ax.scatter(x, RMSEs, s=10, c='b', marker="s")
    figureName = "Adaboost GPS"
    if usePCA:
        figureName += " PCA"
    else:
        figureName += " no PCA"
    fileExt = ".png"
    plt.savefig("./results/" + figureName + fileExt)
    plt.show()
