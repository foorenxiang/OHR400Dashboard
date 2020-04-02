/ IPC definitions
yPredTable:([]timeStamp:();sequence:();throttlePrediction:())
insertyPredTable:{`yPredTable insert x}
clearyPredTable:{delete from `yPredTable;; show"Clearing yPredTable!"} / delete all rows from table
showyPredTable:{show (neg 3*lookbackSteps)#yPredTable}
receiveUpdatedModels:{show "Received updated RLC models!"; show "Using 32bit kdb+ version, cannot run ML models!"}
"Loading telemetry stream processing module"
\l FASProcessTelemetryStream.q