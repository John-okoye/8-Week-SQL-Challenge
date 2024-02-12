--A. Customer Nodes Exploration
--1. How many unique nodes are there on the Data Bank system?
SELECT 
COUNT(DISTINCT customer_nodes.node_id) AS node_count
FROM data_bank.customer_nodes

--2. What is the number of nodes per region?
SELECT region_id,
	   region_name,
	   COUNT(cn.node_id)
FROM data_bank.customer_nodes AS cn
	JOIN data_bank.regions AS r USING(region_id)
GROUP BY region_id, region_name
ORDER BY region_id

--3. How many customers are allocated to each region?
SELECT region_id,
	   region_name,
	   COUNT(DISTINCT cn.customer_id) AS num_customers
FROM data_bank.customer_nodes AS cn
	JOIN data_bank.regions AS r USING(region_id)
GROUP BY region_id, region_name

--4. How many days on average are customers reallocated to a different node?
WITH cte AS 
	(SELECT *,
	   (realloc_date - start_date) AS day_diff
FROM (SELECT *,
		LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS realloc_date
		FROM data_bank.customer_nodes)	
WHERE realloc_date IS NOT NULL)

SELECT ROUND(AVG(day_diff),0) AS avg_realloc_day
FROM cte

--5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
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

--B. Customer Transactions
--1. What is the unique count and total amount for each transaction type?
SELECT
	txn_type AS transaction_type,
	COUNT(txn_type) AS count_of_transc_type,
	sum(txn_amount) AS transc_amount
FROM data_bank.customer_transactions
GROUP BY txn_type

--2. What is the average total historical deposit counts and amounts for all customers?
SELECT 
	ROUND(AVG(txn_type)) AS avg_deposit_count,
	ROUND(AVG(txn_amount)) AS avg_deposit_amount
FROM (
		SELECT
			customer_id,
			COUNT(txn_type) AS txn_type,
			SUM(txn_amount) AS txn_amount
		FROM data_bank.customer_transactions
		WHERE txn_type = 'deposit'
		GROUP BY customer_id
	) AS sub_query

--3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH customer_activity AS
(
	SELECT customer_id,
	       EXTRACT(MONTH FROM txn_date) AS month_id,
	       TO_CHAR(txn_date, 'Month') AS month_name,
	       COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
	       COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
	       COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
FROM data_bank.customer_transactions
GROUP BY customer_id, EXTRACT(MONTH FROM txn_date), TO_CHAR(txn_date, 'Month')
ORDER BY customer_id, month_id
)

SELECT month_id,	
       month_name,
       COUNT(DISTINCT customer_id) AS active_customer_count
FROM customer_activity
WHERE deposit_count > 1
      AND (purchase_count > 0 OR withdrawal_count > 0)
GROUP BY month_id, month_name;

--4. What is the closing balance for each customer at the end of the month?
SELECT 
	customer_id,
	TO_CHAR(txn_date, 'Month') AS transc_month,
	SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN  txn_amount * -1 ELSE txn_amount * 1 END)
	FROM data_bank.customer_transactions
GROUP BY customer_id, transc_month
ORDER BY customer_id, EXTRACT(MONTH FROM MIN(txn_date))

--5. What is the percentage of customers who increase their closing balance by more than 5%?
WITH cte AS (SELECT customer_id, transc_month, closing_amt, prev_month_amt, closing_amt - prev_month_amt AS difference, 
	   (closing_amt - prev_month_amt) / ABS(prev_month_amt):: float as perc_chng
FROM(  
SELECT customer_id,
	   transc_month,
	   closing_amt,
	   LAG(closing_amt) OVER
		(PARTITION BY customer_id ORDER BY customer_id, transc_month) AS prev_month_amt
FROM(SELECT 
	customer_id,
	EXTRACT(MONTH FROM txn_date) AS transc_month,
	SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN  txn_amount * -1 ELSE txn_amount * 1 END) AS closing_amt
	FROM data_bank.customer_transactions
GROUP BY customer_id, transc_month
ORDER BY customer_id, EXTRACT(MONTH FROM txn_date)) )
WHERE (closing_amt - prev_month_amt) / ABS(prev_month_amt) ::float >= 0.05)

SELECT COUNT (DISTINCT customer_id)/ (SELECT COUNT(DISTINCT customer_id) FROM data_bank.customer_transactions) :: float
FROM cte


-- Section C
--1. Running customer balance column that includes the impact each transaction
SELECT customer_id,
       txn_date,
       txn_type,
       txn_amount,
       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
		WHEN txn_type = 'withdrawal' THEN - txn_amount
		WHEN txn_type = 'purchase' THEN - txn_amount ELSE 0 END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM data_bank.customer_transactions;

--2. Customer balance at the end of each month
SELECT 
	customer_id,
	EXTRACT(MONTH FROM txn_date) AS transc_month,
	TO_CHAR(txn_date, 'Month') AS txn_month,
	SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN  txn_amount * -1 ELSE txn_amount END) AS closing_amt
	FROM data_bank.customer_transactions
GROUP BY customer_id, txn_month, transc_month
ORDER BY customer_id, transc_month

--3. Minimum, average and maximum values of the running balance for each customer
SELECT customer_id, ROUND(AVG(running_balance)) AS average, ROUND(MAX(running_balance)) AS maximum, ROUND(MIN(running_balance)) AS minimum
FROM (SELECT customer_id,
       txn_date,
       txn_type,
       txn_amount,
       SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
		WHEN txn_type = 'withdrawal' THEN -txn_amount
		WHEN txn_type = 'purchase' THEN -txn_amount ELSE 0 END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM data_bank.customer_transactions)
GROUP BY customer_id


--Assumption 1: 
--2GB per $100 + 0.5GB

--Option 1: data is allocated based off the amount of money at the end of the previous month
--Using Assumption 1
WITH cte AS(
	SELECT 
		customer_id, 
		month_id,
		month, LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY month_id) AS prev_month_bal
	FROM (
		SELECT 
	    	customer_id,
			EXTRACT(MONTH FROM txn_date) AS month_id,
			TO_CHAR(txn_date, 'Month') AS month,
			SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount ELSE txn_amount END)  AS closing_balance
		FROM data_bank.customer_transactions
		GROUP BY customer_id, month_id, month
		ORDER BY customer_id, month_id
		 )
	  )	 
SELECT month, 
	CAST(SUM(CASE WHEN prev_month_bal >= 0 THEN (prev_month_bal / 100 :: float) * 2 + 0.5
		 WHEN prev_month_bal < 0 THEN 0.5 END) AS NUMERIC (10,2)) data_storage_in_GB
FROM cte
GROUP BY month, month_id
ORDER BY month_id			 	 
			 
--Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--Assumption 1: 2GB/$100 + 0.5GB
SELECT 
	month, 
	CAST(SUM(CASE WHEN prev_month_avg_deposit < 0 THEN 0.5
	   		 WHEN prev_month_avg_deposit >= 0 THEN ((prev_month_avg_deposit/100 :: float)* 2) + 0.5 END) AS NUMERIC(10,2)) AS data_alloc
FROM (
	SELECT 
		customer_id, 
		month_id,
		month, LAG(avg_deposit) OVER (PARTITION BY customer_id ORDER BY month_id) as prev_month_avg_deposit
		
	FROM (
		SELECT 
			customer_id,
			EXTRACT(MONTH FROM txn_date) AS month_id,
			TO_CHAR(txn_date, 'Month') AS month,
			AVG(txn_amount) AS avg_deposit
		FROM data_bank.customer_transactions
		WHERE txn_type = 'deposit'
		GROUP BY customer_id, month_id, month
		ORDER BY customer_id
		 )
	  )	
GROUP BY month, month_id
ORDER BY month_id


--Option 3: data is updated real-time
--Assumption 1: 2GB/$100 + 0.5GB
SELECT
	month, 
	CAST(SUM(data_storage_in_GB)AS NUMERIC(10,2)) AS data_alloc
FROM (
	SELECT 
		customer_id, 
		txn_date, 
		TO_CHAR(txn_date, 'Month') AS month,
		EXTRACT(MONTH FROM txn_date) AS month_id,
		running_balance,
		CASE WHEN running_balance < 0 THEN 0.5 ELSE ((running_balance/100 :: float) * 2) + 0.5 END AS data_storage_in_gb
	FROM (
		SELECT 
		customer_id,
       	txn_date,
		EXTRACT (MONTH FROM txn_date) AS month_id,
		TO_CHAR(txn_date, 'Month') AS month,
       	txn_type,
       	txn_amount,
       	SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
				 WHEN txn_type = 'withdrawal' THEN - txn_amount
				 WHEN txn_type = 'purchase' THEN - txn_amount ELSE 0 END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance
	FROM data_bank.customer_transactions
		 )
	  )	 
GROUP BY month, month_id
ORDER BY month_id



--Section D
SELECT month, 
	   CAST(SUM(CASE WHEN interest > 0 THEN (interest/100 :: float) * 2 ELSE 0 END) AS NUMERIC(10,2)) AS data_alloc
FROM(
SELECT 
	customer_id,
    txn_date,
	EXTRACT (MONTH FROM txn_date) AS month_id,
	TO_CHAR(txn_date, 'Month') AS month,
    txn_type,
    txn_amount,
	running_balance,
	CASE WHEN running_balance > 0 THEN running_balance * 0.000164
		 WHEN running_balance <= 0 THEN 0 END AS interest
FROM (
SELECT 
	customer_id,
    txn_date,
	EXTRACT (MONTH FROM txn_date) AS month_id,
	TO_CHAR(txn_date, 'Month') AS month,
    txn_type,
    txn_amount,
    SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
			 WHEN txn_type = 'withdrawal' THEN - txn_amount
			 WHEN txn_type = 'purchase' THEN - txn_amount ELSE 0 END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM data_bank.customer_transactions)
)	
GROUP BY month, month_id
ORDER BY month_id


 

























































	 
	 
