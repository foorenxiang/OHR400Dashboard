<style>
body{
  text-align: center;
  /*background-color: black;*/
  /*color: white;*/
  font-family: Trebuchet;
  font-size: 20px;
}
header{
  height: 3%;
  font-size: 25px;
}

.headerText{
  font-size:  25px;
  font-weight: bold;
  display:inline;
}

#iframeButton{
  display: inline;
}

#leftColumn{
  float: left;
  text-align: left;
  width: 16%;
  height: 94%;
  padding: 1px 0px 1px 10px; 
  padding-right: 0px;
  border-style: solid;
  border-color: white;
  border-right-color: black;
  border-width: 1px;
}

#rightColumn{
  float: right;
  text-align: left;
  width: 82%;
  height: 94%;
  padding: 1px 10px 1px 0px;
}

iframe{
  border:none;
  width: 80%;
  height: 90%;
  min-width: 1180px;
  min-height: 620px;
}
</style>

<html>
<head>
  <title>Old Holland Road 400 Flight Analysis Platform</title>
  <meta charset="utf-8">
</head>
<body>
<header>
  <strong>Old Holland Road 400 Flight Analysis Platform</strong>
</header>
<div id="KDBstatusBarWrapper" style="text-align: right;">
<div style="color: green; display: inline;">KDB+ Status:</div>
<div id="kdbConnectionIndicator" style="display: inline;"><br></div>
<!-- implement KDB+ websockets so php will automatically call the pre-processor Q script once upload is complete -->
<script>
    var statusIndicator = document.getElementById("kdbConnectionIndicator");
  var ws;
  var cmd;

  function connect(){

    //checks if websocket is supported
    if(!("WebSocket" in window)){
      alert("WebSockets not supported in browser. Required to run pre-processor script!");
      return; //kill script
    }
    
    ws = new WebSocket("ws://localhost:5001/");

    statusIndicator.innerHTML = "Connecting to Q Process";

    //define websocket event handlers
    ws.onopen=function(e){
      statusIndicator.innerHTML="Connected";
    }

    ws.onclose=function(e){
      statusIndicator.innerHTML="Disconnected";
    }

    ws.onerror=function(e){
      statusIndicator.innerHTML="KDB+ instance not up!";
    }

    ws.onmessage=function(e){ 
      /* the message is in plain text, so we need to convert ‘ ’ to ‘&nbsp’ and ‘\n’ to ‘<br />’ in order to display spaces and newlines correctly within the HTML markup*/
      var formattedResponse = e.data.replace(/ /g, '&nbsp').replace(/\n/g, '<br />'); 
      statusIndicator.innerHTML = cmd + formattedResponse + statusIndicator.innerHTML; 
      cmd="";  
    } 
    // statusIndicator.innerHTML="breakpoint";
  }

  function qsend(qCommand){
    ws.send(qCommand);
  }

  function updateKDB(){
    if(ws.readyState === WebSocket.OPEN){
      qCommand ="\\cd /Users/foorx/Sites/OHR400Dashboard";
      ws.send(qCommand);
      qCommand = "\\l FASUpdate.q";
      ws.send(qCommand);
      alert('Updating KDB+!');
    }
    else {
        setTimeout(updateKDB, 2000); // check again in 2 second
    }
  }

  function UpdateModels(){
    if(ws.readyState === WebSocket.OPEN){
      qCommand ="\\cd /Users/foorx/Sites/OHR400Dashboard"
      ws.send(qCommand);
      qCommand = "\\l FASUpdateModels.q"  
      ws.send(qCommand);
      alert('Re-training model!');
    }
    else {
        setTimeout(KDBToPanda, 1000); // check again in a second
    } 
  }

  function LaunchControlPredictions(){
    if(ws.readyState === WebSocket.OPEN){
      qCommand ="\\cd /Users/foorx/Sites/OHR400Dashboard"
      ws.send(qCommand);
      qCommand = "\\l FASUseModel.q"  
      ws.send(qCommand);
      alert('Re-training model!');
    }
    else {
        setTimeout(KDBToPanda, 1000); // check again in a second
    } 
  }

  function ConfirmPurgeDatabase(){
    var r = prompt("Purge database? Type 'purge'");
    if (r == 'purge') {
      purgeDatabase();
    }
  }

  function DownloadRawSampleData(){

  }

  function purgeDatabase(){
    if(ws.readyState === WebSocket.OPEN){
      qCommand ="purgeTables[];"
      ws.send(qCommand);
      alert('Purged database!');
    }
    else {
        setTimeout(purgeDatabase, 1000); // check again in a second
    } 
  }

  connect();
</script>
</div>
<!-- Left Column -->
<!-- Log Upload Interface -->
<div id="leftColumn">
  <div class="headerText">Blackbox Log Upload</div>
  <form method='post' action='' enctype='multipart/form-data'>
   <input type="file" name="file[]" id="file" multiple>
   <input type='submit' name='submit' value='Upload'>
  </form>
  <?php 

  //attempt to connect to kdb instance

  //if no kdb instance is found, spin it up
  // $result = exec("nohup q -p 5001");
  // echo $result;

  //attempt to connect to new instance  

  if(isset($_POST['submit'])){
  $file = '/Users/foorx/logs/logsManifest.csv';
  // Open the file to get existing content
  // $current = file_get_contents($file);
  //Create new file instead
  $current = "numColumns,Files";
   
   // Count total files
   $countfiles = count($_FILES['file']['name']);

    echo "<ol>";
    // Looping all files
    for($i=0;$i<$countfiles;$i++){
      $filename = $_FILES['file']['name'][$i];
      $sourceFile = $_FILES['file']['tmp_name'][$i];
      $destFile = '/Users/foorx/logs/'.$filename;
      // Upload file
      move_uploaded_file($sourceFile,$destFile);
      //echo "<br>";
      echo "<li>Uploaded " . $filename . "</li>";

      $destFile = fopen($destFile, "r"); 
      while ($line = fgetcsv($destFile)) {
        $numcols = count($line);
      }

      echo "Features: " . $numcols . "<br>";

      // Append uploaded csv number of columns and file title to the manifest file
      $current .= "\n".$numcols.",".$filename;
      // Write the contents back to the file
      file_put_contents($file, $current);
    }
    echo "</ol>";

    //run kdb pre-processor script
    echo '<script>updateKDB();</script>';
  } 

  ?>
</div>

<!-- Right Column -->
<div id="rightColumn">
  <!-- <div class="headerText">KDB Server [cd $QHOME/m64/ && rlwrap q PIDajGPSBatch.q -p 5001
]</div><br> -->
<div class="headerText">KDB+ Server[cd $QHOME/m64/ && rlwrap q FASInit.q]</div>
<div id="iframeButton">
  <button onclick="refreshIframe();">Refresh KDB Output</button>
  <button onclick="location.href='localhost:5001/trainingData.csv?select from trainingData';">Download TrainingData</button>
  <button onclick="updateKDB()">Force Update KDB</button>
  <button onclick="UpdateModels()">Update Models</button>
  <button onclick="LaunchControlPredictions()">Predict Throttle</button>
  <button onclick="ConfirmPurgeDatabase()">Purge Database</button>
  <button onclick="DownloadRawSampleData()">Raw Sample Data for Demo</button>
  <script>
    function refreshIframe() {
    var ifr = document.getElementById("kdbiFrame");
    ifr.src = ifr.src;
  }
</script>
</div>
<br>
  <iframe src="http://localhost:5001" id="kdbiFrame"></iframe>
</div>