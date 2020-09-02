import pysftp
from sftpCredentials import sftpCreds

Creds = sftpCreds()

with pysftp.Connection('renxiang.cloud', username=Creds.username, password=Creds.password) as sftp:
    with sftp.cd('/home/foorx/Sites/OHR400Dashboard/'):
        sftp.put('./models/RegressionWindowLSTMModel.model')
        print("Transferred trained LSTM model to kdb server!")
