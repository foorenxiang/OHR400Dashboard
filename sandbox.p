# import numpy as np
# from matplotlib import pyplot as plt

# from sklearn.gaussian_process import GaussianProcessRegressor
# from sklearn.gaussian_process.kernels import RBF, ConstantKernel as C

# import sys
# import pandas as pd

# np.random.seed(1)


# def prediction(x):
#     """The function to predict."""
#     return x * np.sin(x)

# # ----------------------------------------------------------------------
# #  First the noiseless case
# inputPDF = pd.read_csv('trainingData.csv')
# X = inputPDF.copy()
# X.drop(['GPSspeedkph'], axis=1, inplace = True)
# X = X.to_numpy()
# testX = X[int(0.8*len(X)):]
# X = X[:int(0.8*len(X))]

# y = inputPDF.copy()
# y = y['GPSspeedkph']
# y = y.to_numpy()
# testy = y[int(0.8*len(X)):]
# y = y[:int(0.8*len(X))]

# X = np.atleast_2d(X).T
# print("X:")
# print(X)

# # Observations
# print("y:")
# print(y)

# # Mesh the input space for evaluations of the real function, the prediction and
# # its MSE
# # x = np.atleast_2d(np.linspace(0, 10, 1000)).T

# # Instantiate a Gaussian Process model
# kernel = C(1.0, (1e-3, 1e3)) * RBF(10, (1e-2, 1e2))
# gp = GaussianProcessRegressor(kernel=kernel, n_restarts_optimizer=9)

# # Fit to data using Maximum Likelihood Estimation of the parameters
# gp.fit(X, y)

# # Make the prediction on the meshed x-axis (ask for MSE as well)
# y_pred, sigma = gp.predict(x, return_std=True)

# # Plot the function, the prediction and the 95% confidence interval based on
# # the MSE
# plt.figure()
# plt.plot(x, prediction(x), 'r:', label=r'$prediction(x) = x\,\sin(x)$')
# plt.plot(X, y, 'r.', markersize=10, label='Observations')
# plt.plot(x, y_pred, 'b-', label='Prediction')
# plt.fill(np.concatenate([x, x[::-1]]),
#          np.concatenate([y_pred - 1.9600 * sigma,
#                         (y_pred + 1.9600 * sigma)[::-1]]),
#          alpha=.5, fc='b', ec='None', label='95% confidence interval')
# plt.xlabel('$x$')
# plt.ylabel('$prediction(x)$')
# plt.ylim(-10, 20)
# plt.legend(loc='upper left')


# sys.exit(0)

# # ----------------------------------------------------------------------
# # now the noisy case
# X = np.linspace(0.1, 9.9, 20)
# X = np.atleast_2d(X).T

# # Observations and noise
# y = prediction(X).ravel()
# dy = 0.5 + 1.0 * np.random.random(y.shape)
# noise = np.random.normal(0, dy)
# y += noise

# # Instantiate a Gaussian Process model
# gp = GaussianProcessRegressor(kernel=kernel, alpha=dy ** 2,
#                               n_restarts_optimizer=10)

# # Fit to data using Maximum Likelihood Estimation of the parameters
# gp.fit(X, y)

# # Make the prediction on the meshed x-axis (ask for MSE as well)
# y_pred, sigma = gp.predict(x, return_std=True)

# # Plot the function, the prediction and the 95% confidence interval based on
# # the MSE
# plt.figure()
# plt.plot(x, prediction(x), 'r:', label=r'$prediction(x) = x\,\sin(x)$')
# plt.errorbar(X.ravel(), y, dy, fmt='r.', markersize=10, label='Observations')
# plt.plot(x, y_pred, 'b-', label='Prediction')
# plt.fill(np.concatenate([x, x[::-1]]),
#          np.concatenate([y_pred - 1.9600 * sigma,
#                         (y_pred + 1.9600 * sigma)[::-1]]),
#          alpha=.5, fc='b', ec='None', label='95% confidence interval')
# plt.xlabel('$x$')
# plt.ylabel('$prediction(x)$')
# plt.ylim(-10, 20)
# plt.legend(loc='upper left')

# plt.show()

import mysql.connector

mydb = mysql.connector.connect(
  host="localhost",
  user="foorx",
  passwd="Mav3r1ck!",
  database="ml_logs"
)

mycursor = mydb.cursor(buffered=True)

fileName = 'gprModel.p'

file = open(fileName, 'r')
fileData = file.read()
rmse = str(0.00)

#sql = "INSERT INTO customers (name, address) VALUES (%s, %s)"
#val = ("Michelle", "Blue Village")
trainingSetName = 'trainingDataAbove100kph.csv'
sql = "INSERT INTO trainingLogs (fileName,rmse,trainingSetName,fileData) VALUES (%s, %s, %s, %s)"
values = (fileName, rmse, trainingSetName, fileData)
mycursor.execute(sql, values)

mydb.commit()

# for x in values:
	# print(type(x))
	# print(str(values[x]) + type(x))


for x in mycursor:
  print(x)

print(mydb)