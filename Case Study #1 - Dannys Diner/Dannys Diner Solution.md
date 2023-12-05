# :ramen: Case Study #1: Danny's Diner

## Case Study Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
10. What is the total items and amount spent for each member before they became a member?
11. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
12. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
***

###  1. What is the total amount each customer spent at the restaurant?

```sql
SELECT
  s.customer_id,
  CONCAT('$', SUM(m.price)) AS total_spent
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s
  ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

#### Query Result:
| customer_id | total_spent |
| ----------- | ----------- |
| A           | $76         |
| B           | $74         |
| C           | $36         |

***

###  2. How many days has each customer visited the restaurant?

```sql
SELECT
  s.customer_id,
  COUNT(DISTINCT(s.order_date)) AS days_visited
FROM dannys_diner.sales AS s
GROUP BY s.customer_id
```

#### Query Result:
| customer_id | days_visited |
| ----------- | ----------- |
| A           | 4           |
| B           | 6           |
| C           | 2           |

***

###  3. What was the first item from the menu purchased by each customer?
```sql
WITH order_info_cte AS
  (SELECT DISTINCT
    customer_id,
    order_date,
    product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank_num
   FROM dannys_diner.sales AS s
   JOIN dannys_diner.menu AS m
    ON s.product_id = m.product_id)

SELECT
  customer_id,
  product_name,
  order_date
FROM order_info_cte
WHERE rank_num = 1
GROUP BY customer_id,
  product_name,
  order_date;
```

#### Query Result:
| customer_id | product_name | order_date |
| ----------- | ------------ | ---------- |
| A           | curry        | 2021-01-01 |
| A           | sushi        | 2021-01-01 |
| B           | curry        | 2021-01-01 |
| C           | ramen        | 2021-01-01 |

***

###  4. What is the most purchased item on the menu and how many times was it purchased by all customers?
```sql
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
```
#### Query Result:
| product_id | product_name | count |
| ---------- | ----------- | ------ |
| 3          | ramen       | 8      |


***

###  5. Which item was the most popular for each customer?
```sql
WITH order_info AS
  (SELECT
      product_name,
      customer_id,
      count(product_name) AS order_count,
      rank() over(PARTITION BY customer_id ORDER BY count(product_name) DESC) AS rank_num
   FROM dannys_diner.menu
   INNER JOIN dannys_diner.sales
      ON menu.product_id = sales.product_id
   GROUP BY
      customer_id,
      product_name)
SELECT DISTINCT
  customer_id,
  product_name,
  order_count
FROM order_info
WHERE rank_num =1
GROUP BY
  customer_id,
  product_name,
  order_count;
```
#### Query Result:
| customer_id | product_name | order_count |
| ----------- | ------------ | ----------- |
| A           | ramen        | 3           |
| B           | curry        | 2           |
| B           | ramen        | 2           |
| B           | sushi        | 2           |
| C           | ramen        | 3           |

***

###  6. Which item was purchased first by the customer after they became a member?
```sql
WITH member_purchase_info AS
  (SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    mb.join_date,
    rank() over(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank_num
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
```
#### Query Result:
| customer_id | join_date    | order_date               | product_name             |
| ----------- | ------------ | ------------------------ | ------------------------ |
| A           |  2021-01-07  |   2021-01-07             |  curry                   |
| B           |  2021-01-09  |   2021-01-11             |  sushi                   |


***

###  7. Which item was purchased just before the customer became a member?
```sql
WITH member_purchase_info AS
  (SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    mb.join_date,
    rank() over(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank_num
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
```
#### Query Result:
| customer_id | join_date    | order_date               | product_name             |
| ----------- | ------------ | ------------------------ | ------------------------ |
| A           |  2021-01-07  |   2021-01-01             |  sushi                   |
| A           |  2021-01-07  |   2021-01-01             |  curry                   |
| B           |  2021-01-09  |   2021-01-04             |  sushi                   |

***

###  8. What is the total items and amount spent for each member before they became a member?
```sql
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
```
#### Query Result:
| customer_id | total_items | amount_spent |
| ----------- | ----------- | ------------ |
| B           | 3           | $40          |
| A           | 2           | $25          |

***

###  9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
```sql
SELECT
  s.customer_id,
  SUM(CASE WHEN m.product_name = 'sushi' THEN price * 20 ELSE price * 10 END) AS customer_points
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s
  ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY customer_id
```
#### Query Result:
| customer_id | customer_points |
| ----------- | --------------- |
| A           | 860             |
| B           | 940             |
| C           | 360             |


***

###  10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January
#### Breakdown
1. The promo_end_date is 7 days after a customer joins the program (including their join date)
2. Determine the customer points for each transaction and for members with a membership
- During the first week of the membership: customer points = price * 20 irrespective of the purchase item
- When purchase item is sushi and order_date is not within a week of membership: points = price * 20
- When purchse item is not sushi (ramen or curry) and order_date is not within a week of membership: points = price * 10
3. Conditions
- order_date must be before 31st January 2021, that is '2021-01-31' 
- order_date must be greater than or equal to join_date 


```sql
SELECT
  s.customer_id,
  mb.join_date,
  mb.join_date + integer '6' AS promo_end_date,
  SUM(CASE WHEN s.order_date BETWEEN join_date AND mb.join_date + integer '6' THEN price * 20
    WHEN s.order_date >= mb.join_date + integer '6' AND m.product_name = 'sushi' THEN price * 20
    ELSE price * 10 END) AS points
FROM dannys_diner.menu AS m
INNER JOIN dannys_diner.sales AS s
  ON m.product_id = s.product_id
INNER JOIN dannys_diner.members AS mb
  ON s.customer_id = mb.customer_id
WHERE s.order_date <= '2021-01-31' AND s.order_date >= mb.join_date
GROUP BY
  s.customer_id,
  promo_end_date,
  mb.join_date
ORDER BY points DESC;
```
#### Query Result:
| customer_id | join_date    | promo_end_date        | points          |
| ----------- | ------------ | --------------------- | --------------- |
| A           |  2021-01-07  |   2021-01-13          |  1020           |
| B           |  2021-01-09  |   2021-01-15          |  320            |
***

###  Bonus Questions

#### 1. Join All The Things
Create basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL. Fill Member column as 'N' if the purchase was made before becoming a member and 'Y' if the after is amde after joining the membership
```sql
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
```
#### Query Result:
| customer_id | order_date   |  product_name    | price       |  member  |
| ----------- | ------------ | ---------------- | ----------- |  ------- |
| A           |  2021-01-01  |   sushi          |  10         |    N     |
| A           |  2021-01-01  |   curry          |  15         |    N     |
| A           |  2021-01-07  |   curry          |  15         |    Y     |
| A           |  2021-01-10  |   ramen          |  12         |    Y     |
| A           |  2021-01-11  |   ramen          |  12         |    Y     |
| A           |  2021-01-11  |   ramen          |  12         |    Y     |
| B           |  2021-01-01  |   curry          |  15         |    N     |
| B           |  2021-01-02  |   curry          |  15         |    N     |
| B           |  2021-01-04  |   sushi          |  10         |    N     |
| B           |  2021-01-11  |   sushi          |  10         |    Y     |
| B           |  2021-01-16  |   ramen          |  12         |    Y     |
| B           |  2021-02-01  |   ramen          |  12         |    Y     |
| C           |  2021-02-01  |   ramen          |  12         |    N     |
| C           |  2021-02-01  |   ramen          |  12         |    N     |
| C           |  2021-02-07  |   ramen          |  12         |    N     |

***

#### 2. Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.
```sql
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
SELECT
  customer_id,
  order_date,
  product_name,
  price,
  member,
  CASE WHEN member = 'N' THEN null ELSE DENSE_RANK() OVER( PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM ranking
```
#### Query Result:
| customer_id | order_date   |  product_name    | price       |  member  |   ranking  |
| ----------- | ------------ | ---------------- | ----------- |  ------- |  --------- |
| A           |  2021-01-01  |   sushi          |  10         |    N     |    null    |
| A           |  2021-01-01  |   curry          |  15         |    N     |    null    |
| A           |  2021-01-07  |   curry          |  15         |    Y     |      1     |
| A           |  2021-01-10  |   ramen          |  12         |    Y     |      2     |
| A           |  2021-01-11  |   ramen          |  12         |    Y     |      3     |
| A           |  2021-01-11  |   ramen          |  12         |    Y     |      3     |
| B           |  2021-01-01  |   curry          |  15         |    N     |     null   |
| B           |  2021-01-02  |   curry          |  15         |    N     |     null   |
| B           |  2021-01-04  |   sushi          |  10         |    N     |     null   |
| B           |  2021-01-11  |   sushi          |  10         |    Y     |      1     |
| B           |  2021-01-16  |   ramen          |  12         |    Y     |      2     |
| B           |  2021-02-01  |   ramen          |  12         |    Y     |      3     |
| C           |  2021-02-01  |   ramen          |  12         |    N     |     null   |
| C           |  2021-02-01  |   ramen          |  12         |    N     |     null   |
| C           |  2021-02-07  |   ramen          |  12         |    N     |     null   |
***


Click [here](https://github.com/John-okoye/8-Week-SQL-Challenge/blob/main/README.md) to move back to the 8-Week-SQL-Challenge repository!































