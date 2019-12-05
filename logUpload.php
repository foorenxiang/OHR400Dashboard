<style>
body{
  text-align: center;
  /*background-color: black;*/
  /*color: white;*/
  font-family: Trebuchet;
  font-size: 20px;
}
header{
  height: 10%;
  font-size: 25px;
}

header #pageTitle{
  font-size: 35px
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
  height: 85%;
  padding: 10px 0px 5px 10px; 
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
  height: 85%;
  padding: 10px 10px 5px 0px;
}

iframe{
  border:none;
  width: 80%;
  height: 90%;
  min-width: 1180px;
  min-height: 560px;
}
</style>

<html>
<head>
  <title>Old Holland Road 400 Flight Analysis Platform</title>
  <meta charset="utf-8">

</head>
<body>
<header>
  <div id="pageTitle">Old Holland Road 400</div>
  Flight Analysis Platform
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

    statusIndicator.innerHTML = "Connecting to KDB+";

    //define websocket event handlers
    ws.onopen=function(e){
      statusIndicator.innerHTML="KDB+ Connected";
    }

    ws.onclose=function(e){
      statusIndicator.innerHTML="KDB+ disconnected";
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

  function send(){
    // qCommand = "\\l PIDajGPSBatch.q";
    qCommand="qCommand1:5";
    alert("Sending q command: " + '"' + qCommand + '"');
    // alert("qCommand: " + qCommand);
    ws.send(qCommand);
  }

  function loadQScript(){
    if(ws.readyState === WebSocket.OPEN){
      var qCommand = "\\l PIDajGPSBatch.q"  
      ws.send(qCommand);
    }
    else {
        // alert("ws state:" + ws.readyState);
        setTimeout(loadQScript, 1000); // check again in a second
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
  $current = "dummyColumn,Files";
   
   // Count total files
   $countfiles = count($_FILES['file']['name']);

    echo "<ol>";
    // Looping all files
    for($i=0;$i<$countfiles;$i++){
      $filename = $_FILES['file']['name'][$i];
      
      // Upload file
      move_uploaded_file($_FILES['file']['tmp_name'][$i],'/Users/foorx/logs/'.$filename);
      //echo "<br>";
      echo "<li>Uploaded " . $filename . "</li>";

      // Append a new csv title to the file
      $current .= "\n1,".$filename;
      // Write the contents back to the file
      file_put_contents($file, $current);
    }
    echo "</ol>";

    //run kdb pre-processor script
    echo '<script>loadQScript();</script>';
  } 

  ?>
</div>

<!-- Right Column -->
<div id="rightColumn">
  <!-- <div class="headerText">KDB Server [cd $QHOME/m64/ && rlwrap q PIDajGPSBatch.q -p 5001
]</div><br> -->
<div class="headerText">KDB Server [cd $QHOME/m64/ && rlwrap q wsInit.q -p 5001
]</div>
<div id="iframeButton">
  <button onclick="refreshIframe();">Refresh</button>
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