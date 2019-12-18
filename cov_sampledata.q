0N!"Loaded data"; data:("fffffffffffffff";enlist csv) 0: `:/Users/foorx/droneDataset/sampledata.csv;
show meta data;
0N!"linebreak\n";

show ["Covariance of gps altitude against GPS Ground Speed (m/s)"];
show select cov[gpsAlt;gpsSpeedMPS] from data;
0N!"linebreak\n";

show["Discovering how the drone pilot's input covaries with the drone's velocity"];
0N!"linebreak\n";

show ["Covariance of Drone Throttle Value against GPS Ground Speed (m/s)"];
show select cov[ThrottleValRaw;gpsSpeedMPS] from data;
0N!"linebreak\n";

show["Discovering how the drone pilot's input covaries with the actual drone power delivery"];
0N!"linebreak\n";

show ["Covariance of Drone Throttle Value against Motor 1 Output"];
show select cov[ThrottleValRaw;motor1Raw] from data;
0N!"linebreak\n";

show ["Covariance of Drone Throttle Value against Motor 2 Output"];
show select cov[ThrottleValRaw;motor2Raw] from data;
0N!"linebreak\n";

show ["Covariance of Drone Throttle Value against Motor 3 Output"];
show select cov[ThrottleValRaw;motor3Raw] from data;
0N!"linebreak\n";

show ["Covariance of Drone Throttle Value against Motor 4 Output"];
show select cov[ThrottleValRaw;motor4Raw] from data;
0N!"linebreak\n";

show ["Covariance of Drone Throttle Value against drone's acceleration"];
show select cov[ThrottleValRaw;accelerationmps] from data;
0N!"linebreak\n";

show ["Finding covariance of a variable a second variable that is linearly scaled from it"]
show ["Covariance of raw Drone Throttle Value vs remapped as percentage"];
show select cov[ThrottleValRaw;throttleValPercent] from data;
show ["The covariance found is high, but not equals to 1"]
show ["This is due to covariance not being a normalised measure"]

show "--------------------"
show "--------------------"
show "--------------------"
show "measuring correlation"
show "--------------------"
show "--------------------"
show "--------------------"

show ["Correlation of gps altitude against GPS Ground Speed (m/s)"];
show select cor[gpsAlt;gpsSpeedMPS] from data;
0N!"linebreak\n";

show["Discovering how the drone pilot's input correlates with the drone's velocity"];
0N!"linebreak\n";

show ["Correlation of Drone Throttle Value against GPS Ground Speed (m/s)"];
show select cor[ThrottleValRaw;gpsSpeedMPS] from data;
0N!"linebreak\n";

show["Discovering how the drone pilot's input correlates with the actual drone power delivery"];
0N!"linebreak\n";

show ["Correlation of Drone Throttle Value against Motor 1 Output"];
show select cor[ThrottleValRaw;motor1Raw] from data;
0N!"linebreak\n";

show ["Correlation of Drone Throttle Value against Motor 2 Output"];
show select cor[ThrottleValRaw;motor2Raw] from data;
0N!"linebreak\n";

show ["Correlation of Drone Throttle Value against Motor 3 Output"];
show select cor[ThrottleValRaw;motor3Raw] from data;
0N!"linebreak\n";

show ["Correlation of Drone Throttle Value against Motor 4 Output"];
show select cor[ThrottleValRaw;motor4Raw] from data;
0N!"linebreak\n";

show ["Correlation of Drone Throttle Value against drone's acceleration"];
show select cor[ThrottleValRaw;accelerationmps] from data;
0N!"linebreak\n";
