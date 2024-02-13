# 🏦: Case Study #4: Customer Transactions
## Customer Transactions
1. What is the unique count and total amount for each transaction type?
2. What is the average total historical deposit counts and amounts for all customers?
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
4. What is the closing balance for each customer at the end of the month?
5. What is the percentage of customers who increase their closing balance by more than 5%?

***
### 1. What is the unique count and total amount for each transaction type?
```sql
SELECT
  txn_type AS transaction_type,
  COUNT(txn_type) AS count_of_transc_type,
  sum(txn_amount) AS transc_amount
FROM data_bank.customer_transactions
GROUP BY txn_type
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/f43320c8-ec68-4ec0-9c88-5b6858b1712c)

***
### 2. What is the average total historical deposit counts and amounts for all customers?
```sql
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
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/f806a120-6009-48ce-9880-8df0d95fd35f)

***
### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
```sql
WITH customer_activity AS
(
SELECT
  customer_id,
  EXTRACT(MONTH FROM txn_date) AS month_id,
  TO_CHAR(txn_date, 'Month') AS month_name,
  COUNT(CASE WHEN txn_type = 'deposit' THEN 1 END) AS deposit_count,
  COUNT(CASE WHEN txn_type = 'purchase' THEN 1 END) AS purchase_count,
  COUNT(CASE WHEN txn_type = 'withdrawal' THEN 1 END) AS withdrawal_count
FROM data_bank.customer_transactions
GROUP BY customer_id, EXTRACT(MONTH FROM txn_date), TO_CHAR(txn_date, 'Month')
ORDER BY customer_id, month_id
)

SELECT
  month_id,
  month_name,
  COUNT(DISTINCT customer_id) AS active_customer_count
FROM customer_activity
WHERE deposit_count > 1 AND (purchase_count > 0 OR withdrawal_count > 0)
GROUP BY month_id, month_name;
```
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/c856b0db-a89d-4e9e-ba9a-c5284073cc18)

***

### 4. What is the closing balance for each customer at the end of the month?
```sql
SELECT
  customer_id,
  TO_CHAR(txn_date, 'Month') AS transc_month,
  SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN  txn_amount * -1 ELSE txn_amount * 1 END)
FROM data_bank.customer_transactions
GROUP BY customer_id, transc_month
ORDER BY customer_id, EXTRACT(MONTH FROM MIN(txn_date))
```
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/a03a1055-4ab8-4e95-9a1a-4c37655b8327)
*Total Query result is 1720 rows*
####

***
### 5. What is the percentage of customers who increase their closing balance by more than 5%?
```sql
WITH cte AS (SELECT customer_id, transc_month, closing_amt, prev_month_amt, closing_amt - prev_month_amt AS difference, 
	   (closing_amt - prev_month_amt) / ABS(prev_month_amt):: float as perc_chng
FROM(  
SELECT
  customer_id,
  transc_month,
  closing_amt,
  LAG(closing_amt) OVER (PARTITION BY customer_id ORDER BY customer_id, transc_month) AS prev_month_amt
FROM(SELECT
      customer_id,
      EXTRACT(MONTH FROM txn_date) AS transc_month,
      SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN  txn_amount * -1 ELSE txn_amount * 1 END) AS closing_amt
    FROM data_bank.customer_transactions
    GROUP BY customer_id, transc_month
    ORDER BY customer_id, EXTRACT(MONTH FROM txn_date)) )
WHERE (closing_amt - prev_month_amt) / ABS(prev_month_amt) ::float >= 0.05)

SELECT COUNT (DISTINCT customer_id)/ (SELECT COUNT(DISTINCT customer_id) FROM data_bank.customer_transactions) :: float AS percentage
FROM cte
```
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/43e233d2-57ae-4304-8d0d-60b39b5103ab)


***
### Click [here](https://github.com/John-okoye/8-Week-SQL-Challenge/blob/main/Case%20Study%20%234%20-%20Data%20Bank/Data%20Allocation%20Challenge.md) to view the Data Allocation Challenge solution!
