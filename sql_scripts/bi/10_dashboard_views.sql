-- =====================================================
-- 📂 Script: 10_dashboard_views.sql
-- 📌 Description: Dashboard-ready aggregate views (time, product,
--                geo, customer, logistics) on top of the star schema
-- 👩 Author: Daiana Beltrán
-- 📅 Last Updated: 2025-08-17
-- 🔁 Idempotent: yes (drops & recreates views)
-- =====================================================

USE global_superstore_finance;

-- -----------------------------------------------------
-- 0) Housekeeping
-- -----------------------------------------------------
DROP VIEW IF EXISTS vw_dash_overview;
DROP VIEW IF EXISTS vw_dash_time_month;
DROP VIEW IF EXISTS vw_dash_time_quarter;
DROP VIEW IF EXISTS vw_dash_product_cat;
DROP VIEW IF EXISTS vw_dash_product_top25;
DROP VIEW IF EXISTS vw_dash_geo_country;
DROP VIEW IF EXISTS vw_dash_geo_region_state;
DROP VIEW IF EXISTS vw_dash_customer_segment;
DROP VIEW IF EXISTS vw_dash_logistics;

-- =====================================================
-- 1) Executive overview (single row)
-- =====================================================
CREATE VIEW vw_dash_overview AS
SELECT
  MIN(f.order_date)                                           AS min_order_date,
  MAX(f.order_date)                                           AS max_order_date,
  COUNT(DISTINCT f.order_id)                                  AS orders,
  COUNT(DISTINCT f.customer_id)                               AS customers,
  COUNT(DISTINCT f.product_id)                                AS products,
  ROUND(SUM(f.sales), 2)                                      AS total_revenue,
  ROUND(SUM(f.profit), 2)                                     AS total_profit,
  ROUND(100 * SUM(f.profit) / NULLIF(SUM(f.sales), 0), 2)     AS profit_margin_pct,
  ROUND(AVG(f.unit_price_net), 2)                             AS avg_unit_price,
  ROUND(AVG(f.discount_rate) * 100, 2)                        AS avg_discount_pct,
  ROUND(SUM(f.sales) / NULLIF(COUNT(DISTINCT f.order_id),0),2) AS avg_ticket
FROM fact_sales f;

-- =====================================================
-- 2) Time series – monthly (with MoM deltas)
--    Note: We aggregate first, then apply window functions.
-- =====================================================
CREATE VIEW vw_dash_time_month AS
WITH monthly AS (
  SELECT
    d.year,
    d.month,
    d.year_month_key                               AS ´year_month´,
    ROUND(SUM(f.sales), 2)                         AS revenue,
    ROUND(SUM(f.profit), 2)                        AS profit,
    SUM(f.quantity)                                AS qty,
    COUNT(DISTINCT f.order_id)                     AS orders,
    COUNT(DISTINCT f.customer_id)                  AS customers,
    ROUND(100 * SUM(f.profit)/NULLIF(SUM(f.sales),0), 2) AS margin_pct,
    ROUND(SUM(f.sales)/NULLIF(COUNT(DISTINCT f.order_id),0), 2) AS avg_ticket
  FROM fact_sales f
  JOIN dim_date d
    ON f.order_date = d.date
  GROUP BY d.year, d.month, d.year_month_key
)
SELECT
  year,
  month,
  ´year_month´,
  revenue,
  profit,
  qty,
  orders,
  customers,
  margin_pct,
  avg_ticket,
  -- MoM absolute delta
  ROUND(revenue - LAG(revenue) OVER (ORDER BY year, month), 2) AS revenue_mom_delta,
  -- MoM percent delta
  ROUND(
    100 * (revenue - LAG(revenue) OVER (ORDER BY year, month))
        / NULLIF(LAG(revenue) OVER (ORDER BY year, month), 0)
  , 2) AS revenue_mom_pct
FROM monthly
ORDER BY year, month;

-- =====================================================
-- 3) Time series – quarterly
-- =====================================================
CREATE VIEW vw_dash_time_quarter AS
SELECT
  d.year,
  d.quarter,
  CONCAT(d.year, '-Q', d.quarter)                  AS year_quarter,
  ROUND(SUM(f.sales), 2)                           AS revenue,
  ROUND(SUM(f.profit), 2)                          AS profit,
  SUM(f.quantity)                                  AS qty,
  COUNT(DISTINCT f.order_id)                       AS orders,
  ROUND(100 * SUM(f.profit)/NULLIF(SUM(f.sales),0), 2) AS margin_pct
FROM fact_sales f
JOIN dim_date d
  ON f.order_date = d.date
GROUP BY d.year, d.quarter
ORDER BY d.year, d.quarter;

-- =====================================================
-- 4) Product performance – Category / Sub-Category
-- =====================================================
CREATE VIEW vw_dash_product_cat AS
SELECT
  p.category,
  p.sub_category,
  ROUND(SUM(f.sales), 2)                           AS revenue,
  ROUND(SUM(f.profit), 2)                          AS profit,
  SUM(f.quantity)                                  AS qty,
  COUNT(DISTINCT f.product_id)                     AS skus,
  ROUND(100 * SUM(f.profit)/NULLIF(SUM(f.sales),0), 2) AS margin_pct
FROM fact_sales f
JOIN dim_product p
  ON f.product_id = p.product_id
GROUP BY p.category, p.sub_category
ORDER BY revenue DESC;

-- Top 25 products by profit (dashboard bar chart)
CREATE VIEW vw_dash_product_top25 AS
SELECT
  p.product_id,
  p.product_name,
  p.category,
  p.sub_category,
  SUM(f.quantity)                                  AS qty,
  ROUND(SUM(f.sales), 2)                           AS revenue,
  ROUND(SUM(f.profit), 2)                          AS profit,
  ROUND(100 * SUM(f.profit)/NULLIF(SUM(f.sales),0), 2) AS margin_pct
FROM fact_sales f
JOIN dim_product p
  ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category, p.sub_category
ORDER BY profit DESC
LIMIT 25;

-- =====================================================
-- 5) Geography – Country and Region/State
--    We aggregate directly from FACT to avoid dimensional fan-out.
-- =====================================================
CREATE VIEW vw_dash_geo_country AS
SELECT
  f.country,
  ROUND(SUM(f.sales), 2)                           AS revenue,
  ROUND(SUM(f.profit), 2)                          AS profit,
  SUM(f.quantity)                                  AS qty,
  COUNT(DISTINCT f.order_id)                       AS orders,
  ROUND(100 * SUM(f.profit)/NULLIF(SUM(f.sales),0), 2) AS margin_pct
FROM fact_sales f
GROUP BY f.country
ORDER BY revenue DESC;

CREATE VIEW vw_dash_geo_region_state AS
SELECT
  f.region,
  f.state,
  ROUND(SUM(f.sales), 2)                           AS revenue,
  ROUND(SUM(f.profit), 2)                          AS profit,
  SUM(f.quantity)                                  AS qty,
  ROUND(100 * SUM(f.profit)/NULLIF(SUM(f.sales),0), 2) AS margin_pct
FROM fact_sales f
GROUP BY f.region, f.state
ORDER BY revenue DESC;

-- =====================================================
-- 6) Customers – by Segment
-- =====================================================
CREATE VIEW vw_dash_customer_segment AS
SELECT
  f.segment,
  COUNT(DISTINCT f.customer_id)                    AS customers,
  COUNT(DISTINCT f.order_id)                       AS orders,
  ROUND(SUM(f.sales), 2)                           AS revenue,
  ROUND(SUM(f.profit), 2)                          AS profit,
  ROUND(100 * SUM(f.profit)/NULLIF(SUM(f.sales),0), 2) AS margin_pct,
  ROUND(SUM(f.sales)/NULLIF(COUNT(DISTINCT f.order_id),0), 2) AS avg_ticket
FROM fact_sales f
GROUP BY f.segment
ORDER BY revenue DESC;

-- =====================================================
-- 7) Logistics – Shipping Mode & Order Priority
-- =====================================================
CREATE VIEW vw_dash_logistics AS
SELECT
  f.ship_date,
  f.order_priority,
  f.segment,
  ROUND(SUM(f.shipping_cost), 2)                   AS shipping_cost,
  ROUND(SUM(f.sales), 2)                           AS revenue,
  ROUND(SUM(f.profit), 2)                          AS profit,
  COUNT(DISTINCT f.order_id)                       AS orders,
  ROUND(100 * SUM(f.profit)/NULLIF(SUM(f.sales),0), 2) AS margin_pct
FROM fact_sales f
GROUP BY f.ship_date, f.order_priority, f.segment
ORDER BY f.ship_date DESC;


