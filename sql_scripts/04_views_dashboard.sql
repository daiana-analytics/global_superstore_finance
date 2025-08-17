-- =====================================================
-- 📂 Script: 04_views_dashboard.sql
-- 📌 Description: Power BI–ready views (finance KPIs, time series, breakdowns)
-- 👩 Author: Daiana Beltrán
-- 📅 Created: 2025-08-15
-- =====================================================

USE global_superstore_finance;

-- Reset
DROP VIEW IF EXISTS vw_fin_summary;
DROP VIEW IF EXISTS vw_sales_by_month;
DROP VIEW IF EXISTS vw_profit_by_market;
DROP VIEW IF EXISTS vw_profit_by_region;
DROP VIEW IF EXISTS vw_top_products_profit;

-- Finance summary
CREATE VIEW vw_fin_summary AS
SELECT
  ROUND(SUM(sales),2)                                  AS total_revenue,
  ROUND(SUM(profit),2)                                 AS total_profit,
  ROUND(SUM(cost_estimated),2)                         AS total_cost_est,
  ROUND(100 * SUM(profit)/NULLIF(SUM(sales),0),2)      AS gross_margin_pct,
  ROUND(AVG(unit_price_net),2)                         AS avg_unit_price_net,
  ROUND(AVG(discount_rate)*100,2)                      AS avg_discount_pct
FROM gss_orders_clean
WHERE is_valid_sales = 1 AND is_valid_qty = 1;

-- Monthly time series (robust: YEAR/MONTH subquery, no inline comments)
CREATE VIEW vw_sales_by_month AS
SELECT
  d.year_month AS `year_month`,
  SUM(d.sales) AS revenue,
  SUM(d.profit) AS profit,
  SUM(d.cost_estimated) AS cost_est
FROM (
  SELECT
    STR_TO_DATE(
      CONCAT(YEAR(order_date), '-', LPAD(MONTH(order_date), 2, '0'), '-01'),
      '%Y-%m-%d'
    ) AS `year_month`,
    sales,
    profit,
    cost_estimated
  FROM gss_orders_clean
  WHERE is_valid_sales = 1 AND order_date IS NOT NULL
) AS d
GROUP BY d.year_month;

-- Profitability by market
CREATE VIEW vw_profit_by_market AS
SELECT
  market,
  SUM(sales)  AS revenue,
  SUM(profit) AS profit,
  ROUND(100 * SUM(profit)/NULLIF(SUM(sales),0),2) AS margin_pct
FROM gss_orders_clean
WHERE is_valid_sales = 1
GROUP BY market;

-- Profitability by region/country
CREATE VIEW vw_profit_by_region AS
SELECT
  region,
  country,
  SUM(sales)  AS revenue,
  SUM(profit) AS profit,
  ROUND(100 * SUM(profit)/NULLIF(SUM(sales),0),2) AS margin_pct
FROM gss_orders_clean
WHERE is_valid_sales = 1
GROUP BY region, country;

-- Top 10 products by profit
CREATE VIEW vw_top_products_profit AS
SELECT
  product_id,
  product_name,
  category,
  sub_category,
  SUM(quantity) AS qty,
  SUM(sales)    AS revenue,
  SUM(profit)   AS profit
FROM gss_orders_clean
WHERE is_valid_sales = 1
GROUP BY product_id, product_name, category, sub_category
ORDER BY profit DESC
LIMIT 10;


