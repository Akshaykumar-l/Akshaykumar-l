USE akshay_practice;

-- total amount each customer spent at the restaurent
SELECT customer_id,sum(price)
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
group by customer_id;

-- How many days has each customer visited the restaurant
SELECT customer_id,COUNT(DISTINCT(order_date)) as no_of_times_visited
FROM sales
GROUP BY customer_id;
-- what was the first item from the menu purchased by each customer
WITH rankie AS 
(SELECT customer_id,s.product_id,product_name,order_date,
ROW_NUMBER() OVER(PARTITION BY customer_id order by order_date) as	rn
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id)

SELECT customer_id,product_name,rn
FROM rankie
WHERE rn=1;
-- what is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT count(s.product_id) as most_purchased,product_name
FROM sales s
JOIN menu m
ON s.product_id=m.product_id
GROUP BY s.product_id
order by most_purchased desc;
-- Which item was the most popular for each customer?
with filtered as (
SELECT customer_id,product_id,count(product_id) as coun,
dense_rank() over(partition by customer_id order by count(customer_id) desc) as rankie
FROM sales
group by customer_id,product_id)

SELECT customer_id,product_id
FROM filtered 
where rankie=1;

-- Which item was purchased first by the customer after they became a member?
with cte as (
select s.customer_id,product_id,order_date,join_date
from sales s
Join members m
on s.customer_id=m.customer_id
where join_date < order_date
order by order_date
),
ranking as 
(
select customer_id,product_id,order_date,
dense_rank() over(partition by customer_id order by order_date) as rankie
from cte)

select customer_id ,product_id
from ranking
where rankie=1;

-- What is the total items and amount spent for each member before they became a member?
with cte as(
select s.customer_id,product_id,order_date,join_date
from sales s
Join members m
on s.customer_id=m.customer_id
where join_date > order_date
order by order_date),
combo as (
select customer_id,m.product_id,product_name,price,order_date
from cte c
join menu m
on c.product_id=m.product_id
)
select customer_id,count(customer_id) , sum(price) as total_spend
from combo
group by customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?
with cte as(
select customer_id,product_name,
(case when product_name='sushi' then price*20 else price*10 end) as points
from sales s
JOIN menu m
on s.product_id=m.product_id
)

select customer_id,sum(points)
from cte
group by customer_id;

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?
with points_1 as(
select s.customer_id , m.product_id,product_name,price,order_date,join_date,
datediff(order_date,join_date) as diff,
(case when datediff(order_date,join_date) <=7 then price*20 
else (case when datediff(order_date,join_date) >7 and product_name = 'sushi' then  price*20 
else price*10 end) end) as points
from sales s 
join menu m 
on s.product_id=m.product_id
join members mb
on s.customer_id=mb.customer_id
where join_date < order_date and (extract(month from order_date))=1)

select customer_id, sum(points) as total_points
from points_1
group by customer_id
order by total_points desc
