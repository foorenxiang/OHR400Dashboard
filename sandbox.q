table:([]a:1 2; b:`a`b)
tableInput:([]a:4 5;b:`d`e)
tempVar: table
if[`table in key `.; `table set table,tableInput]
table