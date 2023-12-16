-- A. Pizza Metrics
--1. How many pizzas were ordered?
SELECT
	COUNT(*) AS total_ordered_pizzas
FROM pizza_runner.customer_orders;

--2. How many unique customer orders were made?
SELECT
	COUNT(DISTINCT order_id) AS order_count
FROM pizza_runner.customer_orders;

--3. How many successful orders were delivered by each runner?
SELECT
  runner_id,
  COUNT(order_id) AS successful_orders
FROM pizza_runner.runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id
ORDER BY successful_orders DESC;

--4. How many of each type of pizza was delivered?
SELECT
	co.pizza_id,
	pn.pizza_name,
	COUNT(co.pizza_id) AS number_delivered
FROM pizza_runner.customer_orders AS co
	INNER JOIN pizza_runner.pizza_names AS pn
	USING (pizza_id)
GROUP BY co.pizza_id, pn.pizza_name
ORDER BY number_delivered DESC;

--5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
  customer_id,
  SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END) AS meatlovers,
  SUM(CASE WHEN pizza_id = 2 THEN 1 ELSE 0 END) AS vegetarian
FROM pizza_runner.customer_orders
GROUP BY customer_id
ORDER BY customer_id;

--6. What was the maximum number of pizzas delivered in a single order?
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

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
	customer_id,
	SUM (CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS change,
	SUM (CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) AS no_change
FROM pizza_runner.customer_orders
	INNER JOIN pizza_runner.runner_orders
	USING (order_id)
WHERE cancellation IS NULL
GROUP BY customer_id;

--8. How many pizzas were delivered that had both exclusions and extras?
SELECT
	SUM(CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1 ELSE 0 END) AS custom_order_count
FROM pizza_runner.customer_orders
	INNER JOIN pizza_runner.runner_orders
	USING (order_id)
WHERE cancellation IS NULL;

--9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	EXTRACT(HOUR FROM order_time) AS hour_of_day,
	COUNT(order_id) AS total_orders,
	CONCAT(ROUND(COUNT(order_id) / SUM(COUNT(order_id)) OVER() * 100, 1), '%') AS volume_ordered
FROM pizza_runner.customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day;

--10. What was the volume of orders for each day of the week?
SELECT 
	TO_CHAR(order_time, 'Day') AS day_of_week,
	COUNT(order_id) AS total_orders,
	CONCAT(ROUND(COUNT(order_id) / SUM(COUNT(order_id)) OVER() * 100, 1), '%') AS volume_ordered
FROM pizza_runner.customer_orders
GROUP BY day_of_week
ORDER BY total_orders DESC;


-- B. Runner and Customer Experience
--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
    COUNT(runner_id) AS total_runners,
    CASE 
        WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN 'first_week'
        WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-15' THEN 'second_week'
        WHEN registration_date BETWEEN '2021-01-16' AND '2021-01-23' THEN 'third_week'
        WHEN registration_date BETWEEN '2021-01-24' AND '2021-01-31' THEN 'fourth_week'
        ELSE NULL 
    END AS week_category
FROM 
    pizza_runner.runners
WHERE 
    registration_date >= '2021-01-01'
GROUP BY 
    week_category;

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT 
	runner_id,
	ROUND(AVG(EXTRACT(MINUTES FROM pickup_time - order_time)),2) AS avg_min
FROM pizza_runner.runner_orders
INNER JOIN pizza_runner.customer_orders USING (order_id)
GROUP BY runner_id
ORDER BY runner_id

--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
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

--4. What was the average distance travelled for each customer?
SELECT 
	customer_id,
	ROUND(AVG(distance),2) AS avg_distance_km
FROM pizza_runner.customer_orders
INNER JOIN runner_orders USING (order_id)
WHERE cancellation IS NULL
GROUP BY customer_id
ORDER BY customer_id

--5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
	MAX(duration) AS max_duration,
	MIN(duration) AS max_duration,
	MAX(duration) - MIN(duration) AS duration_diff
FROM runner_orders
	
--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
	runner_id,
	distance,
	duration,
	ROUND((distance/(duration/60)),1) AS speed_kmh--Assuming distance is in km/h, convert duration to hours
FROM runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id, speed_kmh

--7. What is the successful delivery percentage for each runner?
SELECT 
	runner_id,
	COUNT(*) AS total_orders,
	COUNT(CASE WHEN cancellation IS NULL THEN 1 END) AS successful_deliv,
	100 * COUNT(CASE WHEN cancellation IS NULL THEN 1 END)/COUNT(*) AS successful_deliv_perc
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id
