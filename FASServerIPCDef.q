/ IPC definitions

/ creates empty prediction table
yPredTable:([]timeStamp:();sequence:();throttlePrediction:())

/ inserts new throttle predictions into yPredTable
insertyPredTable:{`yPredTable insert x}

/ clears the throttle prediction table
clearyPredTable:{delete from `yPredTable;; show"Clearing yPredTable!"} / delete all rows from table

/ shows LSTM lookback steps * 3 rows from the throttle prediction table
showyPredTable:{show (neg 3*lookbackSteps)#yPredTable}

/ Show notification in console when model training script has sent the updated LSTM model to kdb server
receiveUpdatedModels:{show "Received updated RLC models!"; show "Using 32bit kdb+ version, cannot run ML models!"}

"Loading telemetry stream processing module"
\l FASProcessTelemetryStream.q