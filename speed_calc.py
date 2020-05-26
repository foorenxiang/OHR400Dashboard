import numpy as np
import pandas as pd

# Read the csv file
inputPDF = np.asarray(pd.read_csv("gps_data.csv"))

# Enter the trigger speed that denotes the start of a speed run: in m/s
trig_v = 45

# Enter the no. of sample points starting
spl = 4
spl_range = 11


# output
"""
max 100m direction 1		Altitude change in direction 1		Distance covered direction 1		Deviation from horizon			Heading
max 100m direction 2		Altitude change in direction 2		Distance covered direction 2		Deviation from horizon			Heading
Opposite 100m+ Average		Max One way 100m+					Max recorded speed 					Total Deviation from horizon	Angle between opposite Direction Runs
"""
output = np.zeros((3,5))

output[2,1] = inputPDF.max(axis = 0)[5]

print(output)