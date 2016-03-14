LF := FILTER lineitem BY shipdate >= 19950101 AND shipdate <= 19961231;

NF1 := FILTER nation BY n_name == "FRANCE" OR n_name == "GERMANY";

NF := SELECT n_name AS n_name1, n_nationkey AS n_nationkey FROM NF1;
  
SN := SELECT  s_suppkey AS s_suppkey, n_name1 AS n_name1
      FROM supplier JOIN NF ON s_nationkey = n_nationkey;
	  
LJ := SELECT suppkey AS suppkey, price AS price, discount AS discount, shipdate AS shipdate, n_name AS n_name
       FROM LF JOIN orders ON orderkey = o_orderkey
	           JOIN customer ON o_custkey = c_custkey
	           JOIN NF1 ON c_nationkey = n_nationkey;  	
			   
LS := SELECT price AS price, discount AS discount, n_name1 AS n_name1, shipdate AS shipdate, n_name AS n_name
       FROM LJ JOIN SN ON suppkey = s_suppkey;   	   
	   
LF1 := FILTER LS BY n_name1 <> n_name;
				
T := SELECT n_name1 AS n1, n_name AS n2, shipdate/10000 AS shipdate3, price AS price1, discount AS discount1
     FROM LF1;	 
 
G := SELECT n1 AS supp_nation, n2 AS cust_nation, shipdate3 AS shipdate4, SUM(price1*(1-discount1)) AS revenue
     FROM T
     GROUP BY n1, n2, shipdate3; 	 

GO := ORDER G BY supp_nation ASC, cust_nation ASC, shipdate4 ASC;	 
				
STORE GO INTO 'mytest.txt' USING ('|');	