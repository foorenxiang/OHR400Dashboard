/ start IPC TCP/IP broadcast on port 6001 if not already enabled
\p 6001
/ upgrade HTTP protocol to websocket protocol
.z.ws:{neg[.z.w] -8! @[value;x;{`$ "'",x}]}

\cd /Users/foorx/anaconda3/q
/ load embedpy
\l p.q

/ load ml toolkit
\l ml/ml.q
.ml.loadfile`:init.q;
"Machine Learning toolkit loaded"
"Q ML Training Client Process running on port 6001 [websocket mode]"

/ switch back to q working folder
\cd /Users/foorx/Sites/OHR400Dashboard

/ open IPC connection to server
h:hopen 5001
flatDir:h"flatDir"
/ system"l FASUpdateModels.q"
.z.ts:{system"l FASUpdateModels.q";}

reTrainTimer: 6 / in mins
system"t ", string 1000*60*reTrainTimer
hclose