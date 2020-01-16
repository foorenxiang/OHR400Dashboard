%start Q from home directory! ~/
%run the following in terminal to start q with IPC on port 5001 with matlab: rlwrap q -p 5001
%run the following to use q script: rlwrap q featureMatrix.q -p 5001
%note that you can visit localhost:5001 in browser to see what variables
%are in Q memory

q = kx('10.27.38.214',5001);

%%%%%%load the file%%%%%
loadtime = fetch(q, '\t featureMatrix: (71632#"f";enlist csv) 0: `:../../tensorflow/featureMatrix.csv');
%%%%%%load the file%%%%%

%%%%%%%%%%%%%pre-process%%%%%%%%%
fetch(q, 'featureMatrix:(`$ssr[;" ";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;"/";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;"_";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;"(";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;")";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[; "[[]" ;""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;"[]]";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;"[+]";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;"[-]";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;"[*]";""] each trim each string cols featureMatrix)xcol featureMatrix');
fetch(q, 'featureMatrix:(`$ssr[;"[/]";""] each trim each string cols featureMatrix)xcol featureMatrix');

%select 50 features from all features, starting with feature index 5
fetch(q, 'creatingChunk:{featureCols: cols featureMatrix;selectFeatureColsNames: featureCols[x+til (y-x)]; selectedFeatureCols:?[featureMatrix;();0b;selectFeatureColsNames!selectFeatureColsNames]; select from selectedFeatureCols}');
fetch(q, 'chunk:creatingChunk[1;5+50]'); 
%%%%%%%%%%pre-process%%%%%%%%%


%%%%%%%%%%%%%retrieve data from KDB%%%%%%%%%
trainingData = struct2table(fetch(q, 'select from chunk'));

%featuresVector = fetch(q, 'cols featureMatrix');
%fetch(q, 'featuresVector: cols featureMatrix');
%a = fetch(q, 'featuresVector[3]');
%threehundred = fetch(q,'select index:"I"$index, gps_speed:featureCols[3], axis:featureCols[4] from featureMatrix where i within 0 99');
%chunkMatrix = fetch(q,'chunk');