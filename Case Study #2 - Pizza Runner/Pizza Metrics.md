# :pizza: Case Study #2: Pizza runner Solutions
## Pizza Metrics Case Study Questions
1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?

***

###  1. How many pizzas were ordered?
```sql
SELECT
  COUNT(*) AS total_ordered_pizzas
FROM pizza_runner.customer_orders;
```  
#### Query Result:  
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/6e531384-3a16-4411-8d9c-44fd5e2c8df4)

***

###  2. How many unique customer orders were made?
```sql
SELECT
	COUNT(DISTINCT order_id) AS order_count
FROM pizza_runner.customer_orders;
```
#### Query Result: 
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/2b021252-ee53-4837-af5a-fd05c93305e4)

***
### 3. How many successful orders were delivered by each runner?
```sql
SELECT
  runner_id,
  COUNT(order_id) AS successful_orders
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY successful_orders DESC;
```
#### Query Result: 
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/947def87-0f19-4fc6-82c2-a977293cbb8e)

***
### 4. How many of each type of pizza was delivered?
```sql
SELECT
  co.pizza_id,
  pn.pizza_name,
  COUNT(co.pizza_id) AS number_delivered
FROM pizza_runner.customer_orders AS co
  INNER JOIN pizza_runner.pizza_names AS pn
  USING (pizza_id)
GROUP BY co.pizza_id, pn.pizza_name
ORDER BY number_delivered DESC;
```
#### Query Result: 
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/3bfaff21-84f0-4dca-9de1-9817bc342f00)

***
### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT
  customer_id,
  SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS meatlovers,
  SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM pizza_runner.customer_orders
GROUP BY customer_id
ORDER BY customer_id;
```
#### Query Result: 
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/13db45f5-d07e-4c2d-acfc-57d28bb5a864)

***
### 6. What was the maximum number of pizzas delivered in a single order?
```sql
SELECT
  customer_id,
  order_id,
  COUNT(order_id) AS order_count
FROM pizza_runner.customer_orders
  INNER JOIN pizza_runner.runner_orders
  USING (order_id)
WHERE cancellation IS NULL
GROUP BY customer_id, order_id
ORDER BY order_count DESC
LIMIT 1;
```
#### Query Result: 
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/50644325-f197-4302-9788-e5c84e10fb61)

***

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
SELECT
customer_id,
  SUM (CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS change,
  SUM (CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) AS no_change
FROM pizza_runner.customer_orders
  INNER JOIN pizza_runner.runner_orders
  USING (order_id)
WHERE cancellation IS NULL
GROUP BY customer_id;
```
#### Query Result: 
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/f6ba87d8-2abf-4404-8327-7d7860c86711)

***

### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT
  SUM(CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1 ELSE 0 END) AS custom_order_count
FROM pizza_runner.customer_orders
  INNER JOIN pizza_runner.runner_orders
  USING (order_id)
WHERE cancellation IS NULL;
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/88b54b58-e7db-48f1-aa71-4384e40ec534)

***

### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT
  EXTRACT(HOUR FROM order_time) AS hour_of_day,
  COUNT(order_id) AS total_orders,
  CONCAT(ROUND(COUNT(order_id) / SUM(COUNT(order_id)) OVER() * 100, 1), '%') AS volume_ordered
FROM pizza_runner.customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day;
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/d04d1aa3-3185-42e2-af81-534544d3700c)

***

### 10. What was the volume of orders for each day of the week?
```sql
SELECT
  TO_CHAR(order_time, 'Day') AS day_of_week,
  COUNT(order_id) AS total_orders,
  CONCAT(ROUND(COUNT(order_id) / SUM(COUNT(order_id)) OVER() * 100, 1), '%') AS volume_ordered
FROM pizza_runner.customer_orders
GROUP BY day_of_week
ORDER BY total_orders DESC;
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/17608854-9c29-47d4-ac28-f7473cc2e4b2)

***


## Runner and Customer Experience Case Study Questions
1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
4. What was the average distance travelled for each customer?
5. What was the difference between the longest and shortest delivery times for all orders?
6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
7. What is the successful delivery percentage for each runner?
***

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SELECT
  COUNT(runner_id) AS total_runners,
  CASE WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN 'first_week'
    WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-15' THEN 'second_week'
    WHEN registration_date BETWEEN '2021-01-16' AND '2021-01-23' THEN 'third_week'
    WHEN registration_date BETWEEN '2021-01-24' AND '2021-01-31' THEN 'fourth_week'
  ELSE NULL END AS week_category
FROM pizza_runner.runners
WHERE
  registration_date >= '2021-01-01'
GROUP BY week_category;
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/4c65c5d3-87b1-4b7c-a4c7-15f2a67aaf2f)

***

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT 
	runner_id,
	ROUND(AVG(EXTRACT(MINUTES FROM pickup_time - order_time)),2) AS avg_min
FROM pizza_runner.runner_orders
INNER JOIN pizza_runner.customer_orders USING (order_id)
GROUP BY runner_id
ORDER BY runner_id
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/a29ecf91-9fe1-4c65-a654-ba7988a47914)

***

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
WITH size_and_time_relationship AS
	(SELECT 
	 	order_id,
		COUNT(order_id) AS pizza_count,
		EXTRACT(MINUTES FROM pickup_time - order_time) AS prepare_mins
	 FROM pizza_runner.runner_orders
	 INNER JOIN pizza_runner.customer_orders USING (order_id)
	 GROUP BY order_id, prepare_mins
)
SELECT
	pizza_count,
	ROUND(AVG(prepare_mins),0) AS avg_prepare_time
FROM size_and_time_relationship
GROUP BY pizza_count
ORDER BY pizza_count
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/4fac29e8-eb39-4118-a95c-2e1169694ae1)

***

### 4. What was the average distance travelled for each customer?
```sql
SELECT 
	customer_id,
	ROUND(AVG(distance),2) AS avg_distance_km
FROM pizza_runner.customer_orders
INNER JOIN runner_orders USING (order_id)
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/e9fed551-44f0-4df0-b9c8-c3f8ff9ea22a)

***
### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT
	MAX(duration) AS max_duration,
	MIN(duration) AS max_duration,
	MAX(duration) - MIN(duration) AS duration_diff
FROM runner_orders
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/0e16be99-2ff9-4866-8971-18d7aede76ef)

***

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
SELECT
	runner_id,
	distance,
	duration,
	ROUND((distance/(duration/60)),1) AS speed_kmh--Assuming distance is in km/h, convert duration to hours
FROM runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id, speed_kmh
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/71fdee9e-4217-46db-8651-bc774e586889)

***
### 7. What is the successful delivery percentage for each runner?
```sql
SELECT 
	runner_id,
	COUNT(*) AS total_orders,
	COUNT(CASE WHEN cancellation IS NULL THEN 1 END) AS successful_deliv,
	100 * COUNT(CASE WHEN cancellation IS NULL THEN 1 END)/COUNT(*) AS successful_deliv_perc
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id
```
#### Query Result
![image](https://github.com/John-okoye/8-Week-SQL-Challenge/assets/123602109/82d52a2f-a8fc-49bf-984e-6a35a1a2761c)

***


















