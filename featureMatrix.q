/load and time the load
\t featureMatrix: (71632#"f";enlist csv) 0: `:../../../tensorflow/featureMatrix.csv

/remove pesky characters from feature names

featureMatrix:(`$ssr[;" ";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[;"/";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[;"_";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[;"(";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[;")";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[; "[[]" ;""] each trim each string cols featureMatrix)xcol featureMatrix /special characters can be escaped by using square bracket on them!
featureMatrix:(`$ssr[;"[]]";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[;"[+]";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[;"[-]";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[;"[*]";""] each trim each string cols featureMatrix)xcol featureMatrix
featureMatrix:(`$ssr[;"[/]";""] each trim each string cols featureMatrix)xcol featureMatrix
0N! first featureMatrix

/select 50 features from all features (the fully fleshed out way)
/featureCols: cols featureMatrix /create list with names of columns in featureMatrix
/selectFeatureColsNames: featureCols[50+til 3] / create list with names of 3 columns, starting from index 50
/selectedFeatureCols:?[featureMatrix;();0b;selectFeatureColsNames!selectFeatureColsNames] /selects the 3 columns (with all their values!)
/chunk:select from selectedFeatureCols where i within 0 999 / select rows 0 to 999 inclusive

/turning above into function /losing ability to select number of rows
/createChunk function takes 2 args: [firstFeatureIndex; lastFeatureIndex]
/createChunk function returns value as table that has to be assigned!
/returns all rows
creatingChunk:{featureCols: cols featureMatrix;selectFeatureColsNames: featureCols[x+til (y-x)]; selectedFeatureCols:?[featureMatrix;();0b;selectFeatureColsNames!selectFeatureColsNames]; select from selectedFeatureCols}
chunk:creatingChunk[1;4]