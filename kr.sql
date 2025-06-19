
-- Продажи по категориям
SELECT
  p.category,
  SUM(oi.amount) AS total_sales,
  ROUND(SUM(oi.amount) / COUNT(DISTINCT oi.order_id), 2) AS avg_per_order,
  ROUND(SUM(oi.amount) * 100.0 / SUM(SUM(oi.amount)) OVER (), 2) AS category_share
FROM order_items oi
JOIN products p ON oi.product_id = p.id
GROUP BY p.category
ORDER BY total_sales DESC;

-- Анализ покупателей
WITH order_totals AS (
  SELECT
    o.id AS order_id,
    o.customer_id,
    o.order_date,
    SUM(oi.amount) AS order_total
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  GROUP BY o.id, o.customer_id, o.order_date
),
customer_stats AS (
  SELECT
    customer_id,
    SUM(order_total) AS total_spent,
    AVG(order_total) AS avg_order_amount
  FROM order_totals
  GROUP BY customer_id
)
SELECT
  ot.customer_id,
  ot.order_id,
  ot.order_date,
  ot.order_total,
  cs.total_spent,
  ROUND(cs.avg_order_amount, 2) AS avg_order_amount,
  ROUND(ot.order_total - cs.avg_order_amount, 2) AS difference_from_avg
FROM order_totals ot
JOIN customer_stats cs ON ot.customer_id = cs.customer_id
ORDER BY ot.customer_id, ot.order_date;

-- ЗСравнение продаж по месяцам
WITH monthly_sales AS (
  SELECT
    TO_CHAR(o.order_date, 'YYYY-MM') AS year_month,
    DATE_TRUNC('month', o.order_date) AS month_date,
    SUM(oi.amount) AS total_sales
  FROM orders o
  JOIN order_items oi ON o.id = oi.order_id
  GROUP BY 1, 2
),
sales_with_lag AS (
  SELECT
    year_month,
    total_sales,
    LAG(total_sales) OVER (ORDER BY month_date) AS prev_month_sales,
    LAG(total_sales, 12) OVER (ORDER BY month_date) AS prev_year_sales
  FROM monthly_sales
)
SELECT
  year_month,
  total_sales,
  ROUND((total_sales - prev_month_sales) * 100.0 / NULLIF(prev_month_sales, 0), 2) AS prev_month_diff,
  ROUND((total_sales - prev_year_sales) * 100.0 / NULLIF(prev_year_sales, 0), 2) AS prev_year_diff
FROM sales_with_lag
ORDER BY year_month;
