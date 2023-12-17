# :pizza: Case Study #2: Pizza runner Solutions
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


















