CREATE DATABASE Coffee_Shop

USE Coffee_Shop



SELECT * FROM city
SELECT * FROM [customers (1)]
SELECT * FROM products
SELECT * FROM sales


--- 1) Coffee Consumers Count
--How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name,
FORMAT(
(population * 0.25)/1000000,'N2')AS  coffee_consumers  ,city_rank
FROM city
ORDER BY 2 DESC


---2.	Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT
ci.city_name, 
SUM(s.total) AS Total_revenue 
FROM sales AS s
JOIN [customers (1)] AS C
ON s.customer_id = c.customer_id
JOIN city AS ci
ON ci.city_id = C.city_id
WHERE 
DATEPART(YEAR , s.sale_date) = 2023
AND
DATEPART (quarter , s.sale_date)=4
GROUP BY ci.city_name
ORDER BY 2desc

--3.	Sales Count for Each Product
----How many units of each coffee product have been sold?
 
 SELECT p.product_name,
 COUNT(s.sale_id) AS total_orders
 FROM products AS p
 LEFT JOIN sales AS s
 ON s.product_id = p.product_id
 GROUP BY  p.product_name
 ORDER BY 2 DESC

-- 4.	Average Sales Amount per City
--What is the average sales amount per customer in each city?


SELECT 
ci.city_name,
SUM(s.total) as total_revenue,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND(
    CAST(SUM(s.total) AS NUMERIC) /
    CAST(COUNT(DISTINCT s.customer_id) AS NUMERIC),
    2
) AS avg_sale_pr_cx

FROM sales as s
JOIN [customers (1)] as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY  total_revenue DESC

--5.	City Population and Coffee Consumers
--Provide a list of cities along with their populations and estimated coffee consumers.

WITH city_table as (
SELECT city_name,
ROUND((population * 0.25)/1000000, 2) as coffee_consumers

FROM city
),
customers_table AS (
SELECT ci.city_name, COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales as s
JOIN [customers (1)] as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id

GROUP BY ci.city_name
)
SELECT customers_table.city_name,
city_table.coffee_consumers as coffee_consumer_in_millions, customers_table.unique_cx
FROM city_table

JOIN customers_table
ON city_table.city_name = customers_table.city_name


--6.	Top Selling Products by City
--What are the top 3 selling products in each city based on sales volume?
-- Top 3 Selling Products by City

WITH T1 AS (
SELECT ci.city_name, p.product_name,
COUNT(s.sale_id) AS total_orders,
DENSE_RANK() OVER( PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS product_rank
FROM sales AS s

JOIN products AS p
 ON s.product_id = p.product_id
JOIN [customers (1)]AS c
 ON c.customer_id = s.customer_id
JOIN city AS ci
 ON ci.city_id = c.city_id

GROUP BY ci.city_name, p.product_name
)

SELECT * FROM T1
WHERE product_rank <= 3
ORDER BY city_name, product_rank


--7.	Customer Segmentation by City
--How many unique customers are there in each city who have purchased coffee products?

SELECT ci.city_name, COUNT(DISTINCT(c.customer_id)) AS uniqe_customer
FROM sales s
JOIN products AS p
 ON s.product_id = p.product_id
JOIN [customers (1)]AS c
 ON c.customer_id = s.customer_id
JOIN city AS ci
ON ci.city_id = c.city_id
		
GROUP BY ci.city_name
ORDER BY uniqe_customer



--8.	Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer

SELECT
ci.city_name,
COUNT(DISTINCT c.customer_id) AS total_customers,
ROUND(SUM(s.total) * 1.0 / COUNT(DISTINCT c.customer_id), 2) AS avg_sale_per_customer,
ROUND( MAX(ci.estimated_rent) * 1.0 / COUNT(DISTINCT c.customer_id), 2) AS avg_rent_per_customer
FROM sales AS s

JOIN [customers (1)] AS c
ON s.customer_id = c.customer_id

JOIN city AS ci
ON c.city_id = ci.city_id

GROUP BY ci.city_name
ORDER BY avg_sale_per_customer DESC

--9.	Monthly Sales Growth
--Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH monthly_sales AS (
SELECT ci.city_name,
DATEPART(MONTH, sale_date) as month,
DATEPART(YEAR , sale_date) as YEAR,
SUM(s.total) as total_sale
FROM sales as s

JOIN [customers (1)] as c
ON c.customer_id = s.customer_id

JOIN city as ci
ON ci.city_id = c.city_id

GROUP BY ci.city_name,S.sale_date 
),
growth_ratio AS (
SELECT city_name,month,year,total_sale as cr_month_sale,
LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
FROM monthly_sales
)

SELECT
city_name,month,year,cr_month_sale,last_month_sale,
ROUND((cr_month_sale-last_month_sale)/last_month_sale * 100, 2) as growth_ratio

FROM growth_ratio
WHERE last_month_sale IS NOT NULL	

--10.	Market Potential Analysis
--Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


SELECT TOP 3
 ci.city_name,
 ROUND(SUM(s.total), 2) AS total_sales,
 MAX(ci.estimated_rent) AS total_rent,
 COUNT(DISTINCT c.customer_id) AS total_customers,
 ROUND(MAX(ci.population) * 0.40, 0) AS estimated_coffee_consumers
FROM sales AS s

JOIN [customers (1)] AS c
ON s.customer_id = c.customer_id

JOIN city AS ci
ON c.city_id = ci.city_id

GROUP BY ci.city_name
ORDER BY total_sales DESC










