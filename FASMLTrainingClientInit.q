/ select IPC host
hostPort: hsym `renxiang.cloud:5001 / cloud server
/ hostPort: hsym `localhost:5001 / local server

/ get directories
qDirectory: get `:qDirectory
dashboardDirectory: get `:dashboardDirectory
flatDir: get `:flatDir

/ start IPC TCP/IP broadcast on port 6001 if not already enabled
\p 6001
/ upgrade HTTP protocol to websocket protocol
.z.ws:{neg[.z.w] -8! @[value;x;{`$ "'",x}]}

system"cd ",qDirectory
/ load embedpy
\l p.q

/ load ml toolkit
\l ml/ml.q
.ml.loadfile`:init.q;
"Machine Learning toolkit loaded"
"Q ML Training Client Process running on port 6001 [websocket mode]"

/ switch back to q working folder
system"cd ",dashboardDirectory

/ "Pre-importing Python ML libraries"
\l FASPythonLibraries.q

/ open IPC connection to server
h:hopen hostPort
if[(h>0) and hostPort = hsym `renxiang.cloud:5001; show "Connected to kdb master in cloud!"]
if[(h>0) and hostPort = hsym `localhost:5001; show "Connected to kdb master on localhost!"]

"Automatic ML model retraining enabled!"
"Rolling Launch Control Model Trainer Up and Ready"
.z.ts:{system"l FASUpdateModels.q";}

/ reTrainTimer: 6 / in mins
/ system"t ", string 1000*60*reTrainTimer
