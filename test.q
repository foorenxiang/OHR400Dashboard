FASUpdateModels:{realThrottles:(neg 3+lookbackSteps)#trainingData[`rcCommand3];
	realThrottles-:1000;
	realThrottles%:1000;
	realThrottleSlidingWindow: (lookbackSteps)_{1_x,y}\[(lookbackSteps+1)#0;realThrottles];
	columns:{x} each flip realThrottleSlidingWindow;
	realThrottleLSTMTrainingDataMatrix: flip ((lookbackSteps+1)#{`$x}each .Q.a)!columns;
	![realThrottleLSTMTrainingDataMatrix;enlist(=;last cols realThrottleLSTMTrainingDataMatrix;0);0b;`symbol$()];
	.p.set[`inputPDF; .ml.tab2df[(neg lookbackSteps)#realThrottleLSTMTrainingDataMatrix]];
	system"l useRegressionWindowLSTM.p"}