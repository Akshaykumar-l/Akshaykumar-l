use gdb023;

/* Q1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region. */ 

SELECT DISTINCT market AS Atliq_Exclusive_markets
FROM dim_customer
WHERE (customer = 'Atliq Exclusive') and (region = 'APAC');
    
/* Q2. What is the percentage of unique product increase in 2021 vs. 2020? Thefinal output contains these fields,
	unique_products_2020,unique_products_2021,percentage_chg */

-- solution -1

WITH cte1 AS (

	SELECT COUNT(DISTINCT product_code) AS unique_products_2020
FROM fact_gross_price
WHERE fiscal_year = 2020),

cte2 AS (

	SELECT count(DISTINCT product_code) AS unique_products_2021
FROM fact_gross_price
WHERE fiscal_year =2021)

SELECT 	unique_products_2020 ,unique_products_2021, 
    	ROUND((unique_products_2021-unique_products_2020)/unique_products_2020*100,2) AS percentage_chg
FROM cte1
JOIN cte2;

/* solution-2 */
SELECT 
    SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END) AS unique_products_2020,
    SUM(CASE WHEN fiscal_year = 2021 THEN 1 ELSE 0 END) AS unique_products_2021,
    (
SUM(CASE WHEN fiscal_year = 2021 THEN 1 ELSE 0 END)- SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END)
    ) / SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END) * 100 AS percentage_chg
FROM fact_gross_price;


/* Q3. Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
 	The final output contains 2 fields,segment product_count */
 
SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


/* Q4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
		  segment product_count_2020 product_count_2021 difference*/

SELECT segment,
    SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END) AS product_count_2020,
    SUM(CASE WHEN fiscal_year = 2021 THEN 1 ELSE 0 END) AS product_count_2021,
    (
      SUM(CASE WHEN fiscal_year = 2021 THEN 1 ELSE 0 END) - SUM(CASE WHEN fiscal_year = 2020 THEN 1 ELSE 0 END)
    ) AS difference

FROM fact_gross_price
LEFT JOIN dim_product 
USING (product_code)
GROUP BY segment
ORDER BY difference DESC;

/* Q5. 	Get the products that have the highest and lowest manufacturing costs.
	The final output should contain these fields,product_code,product,manufacturing_cost.*/

WITH cte1 AS 
(
	SELECT product_code,product,manufacturing_cost,
	RANK() OVER(ORDER BY manufacturing_cost DESC) AS product_rank
	FROM fact_manufacturing_cost
	LEFT JOIN dim_product
	USING (product_code)
)

(SELECT product_code,product,manufacturing_cost,product_rank
FROM cte1
ORDER BY product_rank ASC
LIMIT 1) 
	UNION
(SELECT product_code, product,manufacturing_cost,product_rank
FROM cte1
ORDER BY product_rank DESC
LIMIT 1);


/* Q6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
	Indian market. The final output contains these fields,customer_code customer average_discount_percentage */

SELECT customer_code,customer,AVG(pre_invoice_discount_pct) AS average_discount_percentage
FROM fact_pre_invoice_deductions
LEFT JOIN dim_customer 
USING (customer_code)
WHERE fiscal_year = 2021 AND market = 'India'
GROUP BY customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* Q7.	Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
	This analysis helps to get an idea of low and high-performing months and take strategic decisions.
	The final report contains these columns:Month,Year,Gross sales Amount */

WITH cte1 AS 
( SELECT customer_code,
	product_code,
	sold_quantity,
	fiscal_year,
	extract(YEAR from date) AS Year,
	extract(month from date) AS Month 
FROM fact_sales_monthly
LEFT JOIN dim_customer
USING (customer_code)
WHERE market = 'India' AND customer = 'Atliq Exclusive'
)

SELECT Month,
	Year,
	ROUND(sum((sold_quantity*gross_price)),2) AS gross_sale_amount
FROM cte1
LEFT JOIN fact_gross_price
USING (product_code,fiscal_year)
GROUP BY Month ,Year;


/* Q8. 	In which quarter of 2020, got the maximum total_sold_quantity? 
	The final output contains these fields sorted by the total_sold_quantity,
	Quarter , total_sold_quantity*/

SELECT QUARTER(date) AS Quarter , 
	SUM(sold_quantity) AS total_sold_quantity

FROM fact_sales_monthly
LEFT JOIN dim_customer
USING (customer_code)

WHERE YEAR(date) = 2020
GROUP BY QUARTER(date)
ORDER BY total_sold_quantity DESC;


/* Q9. 	Which channel helped to bring more gross sales in the fiscal year 2021
	and the percentage of contribution? The final output contains these fields,channel,gross_sales_mln,percentage */

WITH cte1 AS 
(
	SELECT channel, 
	ROUND(SUM((sold_quantity*gross_price))/1000000,2) AS gross_sales_mln
	FROM fact_sales_monthly
	
	LEFT JOIN dim_customer
	USING (customer_code)

	LEFT JOIN fact_gross_price
	USING (product_code , fiscal_year)
	WHERE fiscal_year = 2021
	GROUP BY  channel
	ORDER BY gross_sales_mln DESC
)

SELECT  channel,
    	gross_sales_mln,
    	ROUND((gross_sales_mln / (SELECT SUM(gross_sales_mln) FROM cte1)) * 100,2) AS percentage
FROM cte1
LIMIT 1;


/* Q10. Get the Top 3 products in each division that have a high
	total_sold_quantity in the fiscal_year 2021? The final output contains these
	fields division,product_code,product,total_sold_quantity,rank_order .*/

WITH cte1 AS 
(
	SELECT division,
		product_code,
		product,
		SUM(sold_quantity) AS total_sold_quantity 
	FROM fact_sales_monthly
	LEFT JOIN dim_product
	USING (product_code)

	WHERE fiscal_year = 2021
	GROUP BY division,product
),
cte3 AS 
(
	SELECT *,
	RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
	FROM cte1)
SELECT *
FROM cte3 
WHERE rank_order<4

/* ---------------------------------------END----------------------------------------------*/
