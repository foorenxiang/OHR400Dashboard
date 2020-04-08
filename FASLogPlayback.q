/ start IPC TCP/IP broadcast on port 6003 if not already enabled
\p 6003
/ upgrade HTTP protocol to websocket protocol
.z.ws:{neg[.z.w] -8! @[value;x;{`$ "'",x}]}

"Q Process running on port 6003 [websocket mode]"

hostPort: hsym `renxiang.cloud:5001:foorx:foorxaccess / cloud server
/ hostPort: hsym `localhost:5001:foorx:foorxaccess / local server
/ open IPC connection to server
h:hopen hostPort
flatDir: get `:flatDir
fullLog: get hsym `$flatDir,"fullLog"

"Enabling immediate mode for Garbage Collection"
\g 1

/ convert to json string to simulate mavlink input format
mavlinkInputFormat:.j.j each 0! fullLog

/ require double colon to assign in place global variables
sendDatapoint: {if[count mavlinkInputFormat>0; {neg[h] (`processTelemetryStreamBuffer; x)} mavlinkInputFormat 0; mavlinkInputFormat::1_mavlinkInputFormat; show "Samples streamed: ",string (count fullLog) - count mavlinkInputFormat]}
.z.ts:{sendDatapoint[]}

/ send new sample every 0.2s
\t 200