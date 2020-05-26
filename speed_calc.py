import numpy as np
import pandas as pd

# Read the csv file
inputPDF = np.asarray(pd.read_csv("gps_data.csv"))

# Enter the trigger speed that denotes the start of a speed run: in m/s
trig_v = 45

# Enter the no. of sample points starting
spl_start = 6
spl_range = 11

delta_t = np.zeros([inputPDF.shape[0]])
delta_h = np.zeros([inputPDF.shape[0]])
delta_d = np.zeros([inputPDF.shape[0]])

for i in range(1,inputPDF.shape[0]):
	delta_t[i] = (inputPDF[i,0] - inputPDF[i-1,0])/1000000
	delta_h[i] = inputPDF[i,4] - inputPDF[0,4]
	delta_d[i] = delta_t[i] * inputPDF[i, 5]


set_heading = True

top_speed = []

for spl in range(spl_start, spl_range):
	for i in range(inputPDF.shape[0]):
		if inputPDF[i, 5] > trig_v:
			distance = sum(delta_d[i-spl+1:i+1])
			if distance>100:
				speed = distance/(inputPDF[i,0] - inputPDF[i-spl,0])*1000000
				heading = inputPDF[i, 6]
				altitude = delta_h[i] - delta_h[i-spl]
				angle_deviation = np.arctan(altitude/distance)*180/3.1415926
				top_speed.append((speed, altitude, distance, angle_deviation, heading))

				if set_heading==True:
					set_heading = False
					heading_init = heading

direction_1 = []
direction_2 = []

for run in top_speed:
	if np.abs(run[-1] - heading_init) > 90:
		direction_2.append(run)
	else: direction_1.append(run)

direction_1 = np.asarray(direction_1)
direction_2 = np.asarray(direction_2)

direction_1 = direction_1[direction_1[:,0].argsort()[::-1]]
direction_2 = direction_2[direction_2[:,0].argsort()[::-1]]
output = (direction_1[0] + direction_2[0])/2
output[1] = direction_1[0,0] if direction_1[0,0]>direction_2[0,0] else direction_2[0,0]
output[2] = inputPDF.max(axis = 0)[5]
output[4] = np.abs(direction_1[0,4] - direction_2[0,4])


"""
Direction 1: max 100m direction 1		Altitude change in direction 1		Distance covered direction 1		Deviation from horizon			Heading
Direction 2: max 100m direction 2		Altitude change in direction 2		Distance covered direction 2		Deviation from horizon			Heading
Output:		Opposite 100m+ Average		Max One way 100m+					Max recorded speed 					Total Deviation from horizon	Angle between opposite Direction Runs
"""

print(direction_1[0])
print(direction_2[0])
print(output)