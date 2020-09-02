import numpy as np

# define functions


def rmse(x):
    np.sqrt(np.mean(x**2))


actualGPSSpeed = inputPDF["GPSspeedkph"].to_numpy()
# gps Speed Predictions in KDB shared memory
gpsSpeedError = (gpsSpeedPredictions - actualGPSSpeed)
# rmse error
gpsSpeedRMSEError = rmse(gpsSpeedError)

print("GPS speed predictions: ")
for x in gpsSpeedPredictions:
    print("{0:.2f}".format(x) + 'kph')
print("\n")


print("Actual gps speed:")
for x in actualGPSSpeed:
    print("{0:.2f}".format(x) + 'kph')
print("\n")


print("Raw errors:")
for x in gpsSpeedError:
    print("{0:.2f}".format(x) + '%')
print("\n")


print("RMSE errors:")
print(gpsSpeedRMSEError)
print("\n")
