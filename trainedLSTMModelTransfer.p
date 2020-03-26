import pysftp

with pysftp.Connection('renxiang.cloud', username='foorx', password='Mav3r1ck!') as sftp:
    with sftp.cd('/home/foorx/Sites/OHR400Dashboard/'):
        sftp.put('./RegressionWindowLSTMModel.joblib')