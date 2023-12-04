--1. What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id,
    SUM(price) AS total_spent
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s
	ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

--2. How many days has each customer visited the restaurant?
SELECT 
	s.customer_id,
	COUNT(DISTINCT(s.order_date)) AS days_visited
FROM dannys_diner.sales AS s
GROUP BY s.customer_id

--3. What was the first item from the menu purchased by each customer?	
WITH order_info_cte AS
  (SELECT DISTINCT
		 customer_id,
         order_date,
         product_name,
         DENSE_RANK() OVER(PARTITION BY s.customer_id
                            ORDER BY s.order_date) AS rank_num
   FROM dannys_diner.sales AS s
   JOIN dannys_diner.menu AS m ON s.product_id = m.product_id)

SELECT 
	customer_id,
    product_name,
	order_date
FROM order_info_cte
WHERE rank_num = 1
GROUP BY customer_id,
         product_name,
		 order_date;
	
--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	m.product_id,
	m.product_name,
	COUNT(m.product_name)
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s
	ON m.product_id = s.product_id
GROUP BY m.product_name, m.product_id 
ORDER BY count DESC
LIMIT 1;

--5. Which item was the most popular for each customer?
WITH order_info AS
  (SELECT product_name,
          customer_id,
          count(product_name) AS order_count,
          rank() over(PARTITION BY customer_id
                      ORDER BY count(product_name) DESC) AS rank_num
   FROM dannys_diner.menu
   INNER JOIN dannys_diner.sales
   	ON menu.product_id = sales.product_id
   GROUP BY customer_id,
            product_name)
SELECT DISTINCT
	customer_id,
    product_name,
    order_count
FROM order_info
WHERE rank_num =1
GROUP BY customer_id, product_name, order_count;

--6. Which item was purchased first by the customer after they became a member?
WITH member_purchase_info AS
	(SELECT 
		s.customer_id,
		s.order_date,
		m.product_name,
		mb.join_date,
		rank() over(PARTITION BY s.customer_id
                      ORDER BY s.order_date) AS rank_num
	FROM dannys_diner.sales AS s
	INNER JOIN dannys_diner.members AS mb
		ON s.customer_id = mb.customer_id
	LEFT JOIN dannys_diner.menu AS m
		ON s.product_id = m.product_id
	WHERE s.order_date >= mb.join_date
	)
SELECT
	customer_id,
	join_date,
	order_date,
	product_name
FROM member_purchase_info
WHERE rank_num = 1;

--7. Which item was purchased just before the customer became a member?
WITH member_purchase_info AS
	(SELECT 
		s.customer_id,
		s.order_date,
		m.product_name,
		mb.join_date,
		rank() over(PARTITION BY s.customer_id
                      ORDER BY s.order_date DESC) AS rank_num
	FROM dannys_diner.sales AS s
	INNER JOIN dannys_diner.members AS mb
		ON s.customer_id = mb.customer_id
	LEFT JOIN dannys_diner.menu AS m
		ON s.product_id = m.product_id
	WHERE s.order_date < mb.join_date
	)
SELECT
	customer_id,
	join_date,
	order_date,
	product_name
FROM member_purchase_info
WHERE rank_num = 1;

--8. What is the total items and amount spent for each member before they became a member?
SELECT 
	s.customer_id,
	COUNT(m.product_name) AS total_items,
	CONCAT('$', SUM(m.price)) AS amount_spent
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.members AS mb
	ON s.customer_id = mb.customer_id
LEFT JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id
ORDER BY amount_spent DESC 		

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
	s.customer_id,
	SUM(CASE WHEN m.product_name = 'sushi' THEN price * 20
	 	ELSE price * 10 END) AS customer_points
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s
	ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY customer_id


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
SELECT 
	s.customer_id,
	mb.join_date + integer '7' AS promo_date,
	mb.join_date,
	SUM(CASE WHEN s.order_date BETWEEN join_date AND mb.join_date + integer '7' THEN price * 20
	   	WHEN s.order_date >= mb.join_date + integer '7' AND m.product_name = 'sushi' THEN price * 20
	    ELSE price * 10 END) AS points
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s
	ON m.product_id = s.product_id
INNER JOIN dannys_diner.members AS mb
	ON s.customer_id = mb.customer_id
WHERE s.order_date <= '2021-01-31' AND s.order_date >= mb.join_date
GROUP BY s.customer_id,
		 promo_date,
		 mb.join_date


--Bonus Question 1
SELECT
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	CASE WHEN s.order_date >= mb.join_date THEN 'Y' ELSE 'N' END AS member
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s
	ON m.product_id = s.product_id
LEFT JOIN dannys_diner.members AS mb
	ON s.customer_id = mb.customer_id
ORDER BY customer_id, s.order_date


--Bonus Question 2
WITH ranking AS 
	(SELECT
		s.customer_id,
		s.order_date,
		m.product_name,
		m.price,
		CASE WHEN s.order_date >= mb.join_date THEN 'Y' ELSE 'N' END AS member
		FROM dannys_diner.menu AS m
		INNER JOIN dannys_diner.sales AS s
			ON m.product_id = s.product_id
		LEFT JOIN dannys_diner.members AS mb
			ON s.customer_id = mb.customer_id
		ORDER BY customer_id, s.order_date
)
SELECT customer_id,
	   order_date,
	   product_name,
	   price,
	   member,
	   CASE WHEN member = 'N' THEN null ELSE DENSE_RANK() OVER( PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM ranking
