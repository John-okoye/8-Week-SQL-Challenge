# 🏦: Case Study #4: Customer Nodes Exploration
## Customer Nodes Exploration 
1. How many unique nodes are there on the Data Bank system?
2. What is the number of nodes per region?
3. How many customers are allocated to each region?
4. How many days on average are customers reallocated to a different node?
5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

***

### 1. How many unique nodes are there on the Data Bank system?
```sql
SELECT 
COUNT(DISTINCT customer_nodes.node_id) AS node_count
FROM data_bank.customer_nodes
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/be98b677-8577-4432-9a7c-b22674330cc0)

***

### 2. What is the number of nodes per region?
```sql
SELECT
   region_id,
   region_name,
   COUNT(cn.node_id)
FROM data_bank.customer_nodes AS cn
   JOIN data_bank.regions AS r USING(region_id)
GROUP BY region_id, region_name
ORDER BY region_id
```
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/28159c37-ec5e-43ea-b63e-83418d85c36d)

***

### 3. How many customers are allocated to each region?
```sql
SELECT
   region_id,
   region_name,
   COUNT(DISTINCT cn.customer_id) AS num_customers
FROM data_bank.customer_nodes AS cn
   JOIN data_bank.regions AS r USING(region_id)
GROUP BY region_id, region_name
```
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/1bf5e3ef-99b2-4a3b-bfef-6cc292caab3a)

***

### 4. How many days on average are customers reallocated to a different node?
```sql
WITH cte AS 
	(SELECT *,
	   (realloc_date - start_date) AS day_diff
FROM (SELECT *,
	LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS realloc_date
      FROM data_bank.customer_nodes)	
WHERE realloc_date IS NOT NULL)

SELECT ROUND(AVG(day_diff),0) AS avg_realloc_day
FROM cte
```
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/65722df2-89e8-4925-9b30-efb774c4b9ea)

***


### 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
```sql
WITH cte AS 
	(SELECT *,
	   (realloc_date - start_date) AS day_diff
FROM (SELECT *,
       LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS realloc_date
      FROM data_bank.customer_nodes)	
WHERE realloc_date IS NOT NULL)

SELECT
   region_name,
   ROUND(AVG(day_diff),1) as avg_days,
   percentile_cont(0.5) WITHIN GROUP (ORDER BY day_diff) AS median,
   percentile_cont(0.8) WITHIN GROUP (ORDER BY day_diff) AS percentile_80,
   percentile_cont(0.95) WITHIN GROUP (ORDER BY day_diff) AS percentile_95
FROM cte AS cn
   JOIN data_bank.regions AS r USING(region_id)
WHERE end_date <= '2020-12-31'
GROUP BY region_name
ORDER BY region_name;
```
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/532cafa3-633e-4843-95be-0035726bb9ab)

***

Click [here](https://github.com/John-okoye/8-Week-SQL-Challenge/blob/main/Case%20Study%20%234%20-%20Data%20Bank/Customer%20Transactions.md) to view the Customer Transactions solution!
