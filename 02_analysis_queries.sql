-- =====================================================================
-- 02_analysis_queries.sql
-- 10 commonly asked SQL analysis queries on the Superstore database.
-- Dialect: SQLite. Each query lists the concept it demonstrates.
-- =====================================================================

-- Q1. Overall KPIs
-- Concept: aggregate functions, COUNT(DISTINCT)
-- Check: totals match the Power BI dashboard (2.3M sales, 286K profit, 12.5% margin, 5,009 orders)
SELECT ROUND(SUM(sales), 0)                            AS total_sales,
       ROUND(SUM(profit), 0)                           AS total_profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1)      AS profit_margin_pct,
       COUNT(DISTINCT order_id)                        AS total_orders,
       SUM(quantity)                                   AS total_quantity,
       ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM order_items;

-- Q2. Sales, profit and margin by category
-- Concept: INNER JOIN, GROUP BY, ORDER BY
SELECT p.category,
       ROUND(SUM(oi.sales), 0)                          AS sales,
       ROUND(SUM(oi.profit), 0)                         AS profit,
       ROUND(100.0 * SUM(oi.profit) / SUM(oi.sales), 1) AS margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY sales DESC;

-- Q3. Top 10 customers by total sales
-- Concept: multi-table JOIN, GROUP BY, ORDER BY, LIMIT
SELECT c.customer_name, c.segment,
       COUNT(DISTINCT o.order_id) AS orders,
       ROUND(SUM(oi.sales), 0)    AS sales,
       ROUND(SUM(oi.profit), 0)   AS profit
FROM order_items oi
JOIN orders    o ON o.order_id    = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.segment
ORDER BY sales DESC
LIMIT 10;

-- Q4. Sub-categories that lose money
-- Concept: HAVING (filters groups after aggregation, unlike WHERE)
SELECT p.category, p.sub_category,
       ROUND(SUM(oi.sales), 0)  AS sales,
       ROUND(SUM(oi.profit), 0) AS profit
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category, p.sub_category
HAVING SUM(oi.profit) < 0
ORDER BY profit;

-- Q5. How does the discount level affect profit?
-- Concept: CASE WHEN to create buckets
SELECT CASE
           WHEN discount = 0    THEN '1. No discount'
           WHEN discount <= 0.2 THEN '2. Up to 20%'
           WHEN discount <= 0.4 THEN '3. 21-40%'
           ELSE                      '4. Above 40%'
       END                                            AS discount_band,
       COUNT(*)                                       AS line_items,
       ROUND(SUM(sales), 0)                           AS sales,
       ROUND(SUM(profit), 0)                          AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1)     AS margin_pct
FROM order_items
GROUP BY discount_band
ORDER BY discount_band;

-- Q6. Find duplicate records
-- Concept: GROUP BY + HAVING COUNT(*) > 1 (classic data-cleaning question)
SELECT order_id, product_id, sales, quantity, discount, profit, COUNT(*) AS copies
FROM order_items
GROUP BY order_id, product_id, sales, quantity, discount, profit
HAVING COUNT(*) > 1;

-- Q7. Customers who spent more than the average customer
-- Concept: subquery, comparing a group total with an overall average
SELECT c.customer_name,
       ROUND(SUM(oi.sales), 0) AS total_sales
FROM order_items oi
JOIN orders    o ON o.order_id    = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(oi.sales) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT SUM(oi2.sales) AS customer_total
        FROM order_items oi2
        JOIN orders o2 ON o2.order_id = oi2.order_id
        GROUP BY o2.customer_id
    )
)
ORDER BY total_sales DESC
LIMIT 10;

-- Q8. Yearly sales and year-over-year growth
-- Concept: CTE (WITH) + LAG() window function
WITH yearly AS (
    SELECT strftime('%Y', o.order_date) AS year,
           SUM(oi.sales)                AS sales,
           SUM(oi.profit)               AS profit
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    GROUP BY year
)
SELECT year,
       ROUND(sales, 0)  AS sales,
       ROUND(profit, 0) AS profit,
       ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY year))
             / LAG(sales) OVER (ORDER BY year), 1) AS sales_growth_pct
FROM yearly
ORDER BY year;

-- Q9. Monthly sales with a running total
-- Concept: SUM() OVER (ORDER BY ...) cumulative window function
WITH monthly AS (
    SELECT strftime('%Y-%m', o.order_date) AS month,
           SUM(oi.sales)                   AS sales
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    GROUP BY month
)
SELECT month,
       ROUND(sales, 0)                              AS monthly_sales,
       ROUND(SUM(sales) OVER (ORDER BY month), 0)   AS running_total
FROM monthly
ORDER BY month;

-- Q10. Top 3 products by sales within each category
-- Concept: ROW_NUMBER() with PARTITION BY ("top N per group", the most common window question)
WITH product_sales AS (
    SELECT p.category, p.product_name, SUM(oi.sales) AS sales
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_id, p.product_name
),
ranked AS (
    SELECT category, product_name, ROUND(sales, 0) AS sales,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rank_in_category
    FROM product_sales
)
SELECT *
FROM ranked
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;
