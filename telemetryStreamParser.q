/ telemetryStreamBuffer:0 / buffer on q server to receive mavlink telemetry stream published by mavlinkTelemetry.py
/ receiveTelemetryStream:{[x]
/ 	if[98<>type telemetryStreamBuffer;delete telemetryStreamBuffer from `.; telemetryStreamBuffer:x];}
/ 	/ if[98=type telemetryStreamBuffer;telemetryStreamBuffer2, x]} / if telemetryStreamBuffer is table, concat new row
receiveTelemetryStream:{telemetryStreaBuffer: .j.k x}
telemetryStreaBuffer: 0N
telemetryStreamParse:{select telemetryStreamBuffer}