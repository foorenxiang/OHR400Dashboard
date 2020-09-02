import sys
import numpy as np
import pandas as pd
from joblib import dump, load  # model persistance librny
# import mysql.connector
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt

########ELM Dependencies########
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression

from elm import ELMRegressor
from random_hidden_layer import RBFRandomHiddenLayer, SimpleRandomHiddenLayer
########ELM Dependencies########

pd.set_option('display.max_rows', None)
# fallback csv training data if not using kdb data (for testing purposes)
csvTrainingData = 'trainingDataAbove100kph.csv'

# mysql update setup variables
# cannot use __file__ when running in KDB+
fileName = 'updateELMGPSModel.p'
trainingSetName = 'trainingDataAbove100kph.csv'
comments = 'Using ELM'


def mse(pred, actual):
    return ((pred-actual)**2).mean()


def rmse():
    mse**0.5


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

#####APPLYING NORMALISATION TO DATASET AS REQUIRED BY ELM#####
trainXStandardScalar = StandardScaler()
yStandardScalar = StandardScaler()
trainX = trainXStandardScalar.fit_transform(trainX)
trainy = trainingDataTrain["GPSspeedkph"].to_frame()
trainy = yStandardScalar.fit_transform(trainy)
# Index(['timeDeltaus', 'currentSampleHz', 'timeus', 'rcCommand0', 'rcCommand1',
# 'rcCommand2', 'rcCommand3', 'vbatLatestV', 'gyroADC0', 'gyroADC1',
# 'gyroADC2', 'accSmooth0', 'accSmooth1', 'accSmooth2', 'motor0',
# 'motor1', 'motor2', 'motor3'],
# dtype='object')

testX = trainingDataTest.drop(['GPSspeedkph'], axis=1, inplace=False)
testXStandardScalar = StandardScaler()
testX = testXStandardScalar.fit_transform(testX)
testy = trainingDataTest["GPSspeedkph"].to_frame()
#####APPLYING NORMALISATION TO DATASET AS REQUIRED BY ELM#####

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
            principalComponents = pcaModel.components_
            print("principalComponents:")
            print(principalComponents)
        trainX = pd.DataFrame(pcaModel.transform(trainX))
        testX = pd.DataFrame(pcaModel.transform(testX))
if not 'usePCA' in globals():
    print("Not using PCA!")
######if using PCA, determine principal components######

#########test rbf kernel#########
# #########from plot_elm_comparison.p#########
# kernel_names = ["default", "tanh", "tribas", "hardlim", "rbf(0.1)"]
# model_names = list(map(lambda name: name+"GPSSpeedModel", kernel_names))
# nh = 10

# # pass user defined transfer func
# sinsq = (lambda x: np.power(np.sin(x), 2.0))
# srhl_sinsq = SimpleRandomHiddenLayer(n_hidden=nh,
#                                      activation_func=sinsq,
#                                      random_state=0)

# # use internal transfer funcs
# srhl_tanh = SimpleRandomHiddenLayer(n_hidden=nh,
#                                     activation_func='tanh',
#                                     random_state=0)

# srhl_tribas = SimpleRandomHiddenLayer(n_hidden=nh,
#                                       activation_func='tribas',
#                                       random_state=0)

# srhl_hardlim = SimpleRandomHiddenLayer(n_hidden=nh,
#                                        activation_func='hardlim',
#                                        random_state=0)

# # use gaussian RBF
# srhl_rbf = RBFRandomHiddenLayer(n_hidden=nh*2, gamma=0.1, random_state=0)

# log_reg = LogisticRegression(solver='liblinear')
# #ELMRegressor(tanh, regressor = log_reg) and ELMRegressor(srhl_sinsq) transfer functions are not compatible
# #########from plot_elm_comparison.p#########
# print("Testing ELM RBF Kernel")
# #test model
# model = load('elmGPSSpeedModel.joblib')
# # print(testX.columns)
# y_pred= model.predict(testX)

# #calculate mean square error
# MSE = mse(y_pred,testy)
# RMSE = MSE**0.5

# #display mean square error
# # print("Actual vs Predictions:")
# # testy = testy.to_numpy()
# # for i in range(len(y_pred)):
# # 	print(strFloat(testy[i]) + " || " + strFloat(y_pred[i]))
# print("MSE:")
# print(strFloat(MSE))
# print("RMSE:")
# print(strFloat(RMSE))

#########test rbf kernel#########

#########train all elm models#########
# iterate through different numbers of hidden layers
allTrainedELMModels = dict()
maxHiddenLayers = 20

kernel_names = ["default", "tanh", "tribas", "hardlim", "rbf(0.1)"]
model_names = list(map(lambda name: name+"GPSSpeedModel", kernel_names))
for numHiddenLayers in range(1, 1 + maxHiddenLayers):
    print("Number of hidden layers: " + str(numHiddenLayers))

    #########from plot_elm_comparison.p#########

    # pass user defined transfer func
    sinsq = (lambda x: np.power(np.sin(x), 2.0))
    srhl_sinsq = SimpleRandomHiddenLayer(n_hidden=numHiddenLayers,
                                         activation_func=sinsq,
                                         random_state=0)

    # use internal transfer funcs
    srhl_tanh = SimpleRandomHiddenLayer(n_hidden=numHiddenLayers,
                                        activation_func='tanh',
                                        random_state=0)

    srhl_tribas = SimpleRandomHiddenLayer(n_hidden=numHiddenLayers,
                                          activation_func='tribas',
                                          random_state=0)

    srhl_hardlim = SimpleRandomHiddenLayer(n_hidden=numHiddenLayers,
                                           activation_func='hardlim',
                                           random_state=0)

    # use gaussian RBF
    srhl_rbf = RBFRandomHiddenLayer(
        n_hidden=numHiddenLayers*2, gamma=0.1, random_state=0)

    log_reg = LogisticRegression(solver='liblinear')
    # ELMRegressor(tanh, regressor = log_reg) and ELMRegressor(srhl_sinsq) transfer functions are not compatible
    #########from plot_elm_comparison.p#########

    regressors = [ELMRegressor(), ELMRegressor(srhl_tanh), ELMRegressor(
        srhl_tribas), ELMRegressor(srhl_hardlim), ELMRegressor(srhl_rbf)]
    TrainedELMModels = dict()
    # iterate through each kernel
    # for modeltype, model_name, kernel_name in zip(classifiers,model_names,kernel_names):
    for modeltype, model_name, kernel_name in zip(regressors, model_names, kernel_names):
        print("Training kernel: " + kernel_name)
        model = modeltype
        model.fit(trainX, trainy)
        # add trained model to allTrainedELMModels dictionary
        TrainedELMModels[kernel_name] = model
    print()
    # save models from current iteration of hidden layers
    allTrainedELMModels[numHiddenLayers] = TrainedELMModels
#########train all elm models#########

model = None  # erase model from memory

#########test all ELM kernels#########
print("\nTesting all kernels...")

bestHiddenLayerCount, bestModel, bestModelName, bestMSE, bestPrediction = None, None, None, None, None

savedGPSSpeedModel = None
RMSElist = []
hiddenLayerAndKernelRMSEs = dict()
print(kernel_names)
for kernel_name in kernel_names:
    hiddenLayerAndKernelRMSEs[kernel_name] = []

for numHiddenLayers in range(1, 1 + maxHiddenLayers):
    print("\nLayer: " + str(numHiddenLayers))
    for kernel_name in kernel_names:
        print("Testing kernel: " + kernel_name)
        # test model
        model = allTrainedELMModels[numHiddenLayers][kernel_name]
        y_pred = model.predict(testX)  # shape: (215,)
        y_pred = yStandardScalar.inverse_transform(y_pred)

        # calculate mean square error
        MSE = mse(y_pred, np.asarray(testy))
        RMSE = MSE**0.5
        hiddenLayerAndKernelRMSEs[kernel_name].append(RMSE)

        print("MSE:")
        print(MSE)
        print("RMSE:")
        print(strFloat(RMSE))

        improvement = 5  # set improvement percentage here

        improvement /= 100
        improvement = 1 - improvement
        if bestMSE != None:
            if MSE < (bestMSE*improvement):
                bestMSE = MSE
                bestHiddenLayerCount = numHiddenLayers
                bestModel = model
                bestPrediction = y_pred
        else:
            bestMSE = MSE
            bestHiddenLayerCount = numHiddenLayers
            bestModel = model
            bestPrediction = y_pred

modelSave = {"model": bestModel, "usePCA": usePCA,
             "yStandardScalar": yStandardScalar}
if usePCA:
    modelSave["pcaModel"] = pcaModel
savedGPSSpeedModel = dump(modelSave, './models/elmGPSSpeedModel.model')

#####Plot RMSE performance for kernels and hidden layers#####
showPlots = True
if not kdbSource:
    colours = ['b', 'r', 'c', 'm', 'y']
    for kernelName, colour in zip(hiddenLayerAndKernelRMSEs.keys(), colours):
        fig = plt.figure()
        ax = fig.add_subplot(111)
        ax.set(ylim=(0, 100))
        plotTitle = "ELM Regressor " + kernelName
        if usePCA:
            plotTitle += " PCA"
        else:
            plotTitle += " no PCA"
        plotTitle += " Lowest RMSE: " + \
            strFloat(min(hiddenLayerAndKernelRMSEs[kernelName]))
        plt.title(plotTitle)
        plt.xlabel('Hidden layers')
        plt.ylabel('RMSE')
        ax.scatter(list(range(1, maxHiddenLayers+1)),
                   hiddenLayerAndKernelRMSEs[kernelName], s=10, c=colour, marker="s", label=kernelName)
        # plt.legend(loc='upper left');
        figureName = kernelName + " " + str(maxHiddenLayers) + " layers"
        if usePCA:
            figureName += " PCA"
        else:
            figureName += " no PCA"
        fileExt = ".png"
        plt.savefig("./results/" + figureName + fileExt)
        if showPlots:
            plt.show()
#####Plot RMSE performance for kernels and hidden layers#####

print("Optimal model:")
print(bestModel)
print("bestHiddenLayerCount:")
print(bestHiddenLayerCount)
print("MSE: " + str("{:.2f}".format(bestMSE)))
print("RMSE: " + str("{:.2f}".format(bestMSE**0.5)))

if not kdbSource:
    print("Predictions || Actual Speed || Error:")

    Errors = np.asarray(testy) - bestPrediction

    comparisons = []
    for prediction, actual, Error in zip(bestPrediction, np.asarray(testy), Errors):
        comparisons.append((prediction[0], actual[0], Error[0]))

    print(comparisons)
    comparisons.sort(key=lambda x: abs(x[2]))
    for sample in comparisons:
        print(strFloat(sample[0]) + "kph || " + strFloat(sample[1]
                                                         ) + "kph || " + strFloat(sample[2]) + "kph")

#########test all ELM kernels#########
