## Welcome to Alenka - GPU database engine

### What is this?

This is a GPU based database engine written to use vector based processing and high bandwidth of modern GPUs

### Requirements
* CUDA (nvcc) + Nvidia GPU
* bison
* flex
* Modern GPU Library (included as submodule) 

### How to build?

```
git clone --recursive https://github.com/antonmks/Alenka.git
cd Alenka
make
```

### Features :

  *  Vector-based processing  
    CUDA programming model allows a single operation to be applied to an entire set of data at once.
	
  * Smart compression  
    Ultra fast compression and decompression on GPU.
	Database operations on compressed data.
	
  * Column-based storage  
    Minimizes disk I/O by only accessing the relevant data.

  * Data skipping  
    Better performance without indexes.	

  * Fast Loading  
    Gpu based CSV parser loads the data into database at very high speed. 

### How to use it ?

Create your data files :

Run scripts load_orders.sql, load_lineitem.sql and load_customer.sql to create your database files.

Run your queries from a command prompt or use Alenka [JDBC driver](https://github.com/Technica-Corporation/Alenka-JDBC) from Technica Corporation


##### Step 1 - Filter data

` OFI := FILTER orders BY o_orderdate < 19950315;`

` CF := FILTER customers BY c_mktsegment == "BUILDING";`

` LF := FILTER lineitem BY shipdate > 19950315;`

##### Step 2 - Join data

` OLC := SELECT o_orderkey AS o_orderkey, o_orderdate AS o_orderdate,`
` o_shippriority AS o_shippriority, price AS price, discount AS discount`
` FROM LF JOIN OFI ON orderkey = o_orderkey `
` JOIN CF ON o_custkey = c_custkey;`

##### Step 3 - Group data

` F := SELECT o_orderkey AS o_orderkey1, o_orderdate AS orderdate1, `
`o_shippriority AS priority,  SUM(price*(1-discount)) AS sum_revenue,
 COUNT(o_orderkey) AS cnt`  
`FROM OLC GROUP BY o_orderkey, o_orderdate, o_shippriority;`	


##### Step 4 - Order data


`RES := ORDER F BY sum_revenue DESC, orderdate1 ASC;`


##### Step 5 - Save the results 


`STORE RES INTO 'results.txt' USING ('|') LIMIT 10;`


