# reference: https://qpython.readthedocs.io/en/latest/usage-examples.html#asynchronous-query

import random
import threading
import time

from qpython import qconnection
from qpython.qtype import QException
from qpython.qconnection import MessageType
from qpython.qcollection import QDictionary


class ListenerThread(threading.Thread):

    def __init__(self, q):
        super(ListenerThread, self).__init__()
        self.q = q
        self._stopper = threading.Event()

    def stop(self):
        self._stopper.set()

    def stopped(self):
        return self._stopper.isSet()

    def run(self):
        while not self.stopped():
            print('.')
            try:
                message = self.q.receive(data_only = False, raw = False) # retrieve entire message

                if message.type != MessageType.ASYNC:
                    print('Unexpected message, expected message of type: ASYNC')

                print('type: %s, message type: %s, data size: %s, is_compressed: %s ' % (type(message), message.type, message.size, message.is_compressed))
                print(message.data)

                if isinstance(message.data, QDictionary):
                    # stop after 10th query
                    if message.data[b'queryid'] == 9:
                        self.stop()

            except QException as e:
                print(e)


if __name__ == '__main__':
    # create connection object
    q = qconnection.QConnection(host = 'renxiang.cloud', port = 5001, username = 'foorx', password = 'foorxaccess')
    # initialize connection
    q.open()

    print(q)
    print('IPC version: %s. Is connected: %s' % (q.protocol_version, q.is_connected()))

    try:
        # definition of asynchronous multiply function
        # queryid - unique identifier of function call - used to identify
        # the result
        # a, b - parameters to the query
        q.sendSync('    :{[queryid;a;b] res:a*b; (neg .z.w)(`queryid`result!(queryid;res)) }');

        t = ListenerThread(q)
        t.start()

        for x in range(10):
            a = random.randint(1, 100)
            b = random.randint(1, 100)
            print('Asynchronous call with queryid=%s with arguments: %s, %s' % (x, a, b))
            q.sendAsync('asynchMult', x, a, b);

        time.sleep(1)
    finally:
        q.close()   