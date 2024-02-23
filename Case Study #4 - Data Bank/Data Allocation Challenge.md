# 🏦: Case Study #4: Data Allocation Challenge
## Data Allocation
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

- Option 1: data is allocated based off the amount of money at the end of the previous month
- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
- Option 3: data is updated real-time

For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

- running customer balance column that includes the impact each transaction
- customer balance at the end of each month
- minimum, average and maximum values of the running balance for each customer

Using all of the data available - how much data would have been required for each option on a monthly basis?

***
### 1. Running customer balance column that includes the impact each transaction
```sql
SELECT
  customer_id,
  txn_date,
  txn_type,
  txn_amount,
  SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
    WHEN txn_type = 'withdrawal' THEN - txn_amount
    WHEN txn_type = 'purchase' THEN - txn_amount ELSE 0 END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance
FROM data_bank.customer_transactions;
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/04cd111f-990c-4692-8b5e-b866e9a6804a)
*Total Query result is 5868 rows*

### 2. Customer balance at the end of each month
```sql
SELECT
  customer_id,
  EXTRACT(MONTH FROM txn_date) AS transc_month,
  TO_CHAR(txn_date, 'Month') AS txn_month,
  SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN  txn_amount * -1 ELSE txn_amount END) AS closing_amt
FROM data_bank.customer_transactions
GROUP BY customer_id, txn_month, transc_month
ORDER BY customer_id, transc_month
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/3e707593-169d-4d7e-8227-789567d8502e)
*Total Query result is 1720 rows*

### 3. Minimum, average and maximum values of the running balance for each customer
```sql
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
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/605b4fb1-ebc6-4325-8db9-737007468ecb)
*Total Query result is 500 rows*

***
## Data Allocation Options
#### - 2GB per $100 + 0.5GB for customers with a positive balance 
#### - 0.5GB for customers wih credit balances. 
#### Extra 0.5GB for customers with a positive balance is so we can say that any customer with 0.5GB is a customer with negative or 0 balance.

### Option 1: Data is allocated based off the amount of money at the end of the previous month
```sql
WITH cte AS(
    SELECT
      customer_id,
      month_id,
      month,
      LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY month_id) AS prev_month_bal
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
SELECT
  month,
  CAST(SUM(CASE WHEN prev_month_bal >= 0 THEN (prev_month_bal / 100 :: float) * 2 + 0.5
            WHEN prev_month_bal < 0 THEN 0.5 END) AS NUMERIC (10,2)) data_storage_in_GB
FROM cte
GROUP BY month, month_id
ORDER BY month_id	
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/720f1030-34fe-4712-a244-6e21bc4a2925)


### Option 2: Data is allocated on the average amount of money kept in the account in the previous 30 days
```sql
SELECT
  month,
  CAST(SUM(CASE WHEN prev_month_avg_deposit < 0 THEN 0.5
            WHEN prev_month_avg_deposit >= 0 THEN ((prev_month_avg_deposit/100 :: float)* 2) + 0.5 END) AS NUMERIC(10,2)) AS data_storage_in_GB
FROM (
  SELECT
    customer_id,
    month_id,
    month,
    LAG(avg_deposit) OVER (PARTITION BY customer_id ORDER BY month_id) as prev_month_avg_deposit
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
```  
#### Query Result:  
(![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/6f44e072-2dd6-4661-bd9e-b102ea78cb77)

***

### Option 3: Data is updated real-time
```sql
SELECT
  month,
  CAST(SUM(data_storage_in_GB)AS NUMERIC(10,2)) AS data_storage_in_GB
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
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/a41ae9ce-9a06-4337-97f6-2778ce5eb313)


***

### Extra Challenge: Data is allocated using 6% interest rate per annum
```sql
SELECT
  month,
  CAST(SUM(CASE WHEN interest > 0 THEN (interest/100 :: float) * 2 ELSE 0 END) AS NUMERIC(10,2)) AS data_storage_in_GB
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
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/b1b0b2a4-84bb-4c08-8399-5a57159375b2)
***
### Click [here](https://github.com/John-okoye/8-Week-SQL-Challenge/blob/main/Case%20Study%20%234%20-%20Data%20Bank/Extension%20Request%20(Slides).md) to view the Extension Request(Presentation Slides)!
