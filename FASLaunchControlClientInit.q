/ start IPC TCP/IP broadcast on port 6002 if not already enabled
\p 6002
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

/ "Pre-importing Python ML libraries"
\l FASPythonLibraries.q

"Retrieving LSTM lookbackSteps from disk:"
show lookbackSteps: get `:lookbackSteps.dat 

/ open IPC connection to server
h:hopen 5001
flatDir:h"flatDir"
system"l FASUseModels.q"
.z.ts:{FASUseModels[]}

"Rolling Launch Control Generator Up and Ready"

predictionFrequency:1 /in Hz
system"t ",string 1000*1%1