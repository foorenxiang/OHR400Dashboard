<style>
body{
  text-align: center;
  /*background-color: black;*/
  /*color: white;*/
  font-family: Trebuchet;
  font-size: 20px;
}
header{
  height: 7%;
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

#leftColumn{
  float: left;
  text-align: left;
  width: 16%;
  height: 91%;
  padding: 10px 0px 5px 10px; 
  padding-right: 0px;
  border-style: solid;
  border-color: white;
  border-right-color: black;
  border-width: 1px;
}

#rightColumn{
  float: right;
  /*text-align: left;*/
  width: 82%;
  height: 91%;
  padding: 10px 10px 5px 0px;
}

iframe{
  border:none;
}

</style>
<html>
<title>Old Holland Road 400 Flight Analysis Platform</title>
<body>
<header>
  <div id="pageTitle">Old Holland Road 400</div>
  Flight Analysis Platform
</header>


<!-- Left Column -->
<!-- Log Upload Interface -->
<div id="leftColumn">
  <div class="headerText">Blackbox Log Upload</div>
  <form method='post' action='' enctype='multipart/form-data'>
   <input type="file" name="file[]" id="file" multiple>
   <input type='submit' name='submit' value='Upload'>
  </form>
  <?php 
  if(isset($_POST['submit'])){

  $file = '../logs/logsManifest.csv';
  // Open the file to get existing content
  $current = file_get_contents($file);
   
   // Count total files
   $countfiles = count($_FILES['file']['name']);

    echo "<ol>";
    // Looping all files
    for($i=0;$i<$countfiles;$i++){
      $filename = $_FILES['file']['name'][$i];
      
      // Upload file
      move_uploaded_file($_FILES['file']['tmp_name'][$i],'../logs/'.$filename);
      //echo "<br>";
      echo "<li>Uploaded " . $filename . "</li>";

      // Append a new csv title to the file
      $current .= "\n1,".$filename;
      // Write the contents back to the file
      file_put_contents($file, $current);
    }
    echo "</ol>";
  } 
  ?>
</div>

<!-- Right Column -->
<div id="rightColumn">
  <div class="headerText">KDB Server <div style="font-size: 20px; font-weight: normal">[rlwrap q logging -l -p 5001]</div></div><br>
  <iframe src="http://localhost:5001" style="width: 80%; height: 90%; min-width: 1000px; min-height: 600px;"></iframe>
</div>