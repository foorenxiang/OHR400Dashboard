# references:
# https://github.com/nugend/qPython/blob/master/samples/console.py
# https://github.com/T-13/DroneVis/wiki/Betaflight-MAVLink-Telemetry
# https://raw.githubusercontent.com/wiki/T-13/DroneVis/resources/wifi_receive.py

import qpython
from qpython import qconnection
from qpython.qtype import QException
import socket
import json

if __name__ == '__main__':
    HOST = "0.0.0.0"
    PORT = 14550

    with qconnection.QConnection(host='renxiang.cloud', port=5001, username='foorx', password='foorxaccess') as q, socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
        s.bind((HOST, PORT))
        print('kdb+ server:')
        print(q)
        print('IPC version: %s. Is connected: %s' %
              (q.protocol_version, q.is_connected()))
        print("Ready to publish mavlink telemetry to FAS kdb server!")
        while True:
            mavlinkData = s.recv(1024)
            print(data)
            try:
                result = q(mavlinkData)
                print(type(result))
                print(result)
            except QException as msg:
                print('q error: \'%s' % msg)
