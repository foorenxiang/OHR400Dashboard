"Current memory usage"
show .Q.w[]
"***************Running Python Garbage Collector***************"
p)for objectName in ['trainingDataPDF', 'sys', 'plt', 'train_test_split', 'LogisticRegression', 'ELMRegressor', 'RBFRandomHiddenLayer', 'SimpleRandomHiddenLayer', 'csvTrainingData', 'fileName', 'trainingSetName', 'comments', 'mse', 'rmse', 'strFloat', 'kdbSource', 'trainPercentage', 'trainingDataTrain', 'trainingDataTest', 'trainX', 'trainXStandardScalar', 'yStandardScalar', 'trainy', 'testX', 'testXStandardScalar', 'testy', 'usePCA', 'covarianceExplanation', 'pcaModel', 'principalComponents', 'allTrainedELMModels', 'maxHiddenLayers', 'kernel_names', 'model_names', 'numHiddenLayers', 'sinsq', 'srhl_sinsq', 'srhl_tanh', 'srhl_tribas', 'srhl_hardlim', 'srhl_rbf', 'log_reg', 'regressors', 'TrainedELMModels', 'modeltype', 'model_name', 'kernel_name', 'model', 'bestHiddenLayerCount', 'bestModel', 'bestModelName', 'bestMSE', 'bestPrediction', 'savedGPSSpeedModel', 'RMSElist', 'hiddenLayerAndKernelRMSEs', 'y_pred', 'MSE', 'RMSE', 'improvement', 'modelSave', 'showPlots', 'objectName']:
	try:
		del globals()[objectName]
	except:
		pass
p)import gc
p)gc.collect()
"***************Finished Python Garbage Collection***************"
"***************Objects in python globals***************"
p)print(globals().keys())
"***************Objects in python globals***************"
FAS.gc:{show "Current memory usage"; show .Q.w[]; show "Running q Garbage Collector"; .Q.gc[]; show "Memory usage after q garbage collection"; show .Q.w[]}
FAS.gc[]