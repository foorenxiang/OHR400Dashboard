"Current memory usage"
show .Q.w[]
"***************Running Python Garbage Collector***************"
p)for objectName in ['inputPDF', 'sys', 'fileName', 'trainingSetName', 'comments', 'mse', 'strFloat', 'csvTrainingData', 'trainingDataPDFNotFound', 'trainingDataPDF', 'trainPercentage', 'trainingDataTrain', 'lowThrottle', 'highThrottle', 'throttleSteps', 'steps', 'throttleInputRange', 'tempPDF', 'x', 'y', 'inputPDFStandardScalar', 'tempInputPDF', 'modelSave', 'model', 'usePCA', 'yStandardScalar', 'pcaModel', 'gpsSpeedPrediction', 'gpsPredictionPDF', 'throttleInputSequence', 'synthesizedSampleIndexRef']:
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