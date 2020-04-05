/ this script preloads slow loading python dependencies during main loading of kdb script so they are immediately available on call
p)import numpy as np
p)import pandas as pd
p)import math
p)from sklearn.decomposition import PCA
p)import sklearn.gaussian_process as gp
p)from keras.models import Sequential
p)from keras.layers import Dense
p)from keras.layers import LSTM
p)from sklearn.preprocessing import StandardScaler
p)from joblib import dump,load