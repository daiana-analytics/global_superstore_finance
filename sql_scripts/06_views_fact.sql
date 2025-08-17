-- =====================================================
-- 📂 Script: 06_views_fact.sql
-- 📌 Description: Core FACT view for BI reporting
-- 👩 Author: Daiana Beltrán
-- 📅 Created: 2025-08-16
-- =====================================================

USE global_superstore_finance;

DROP VIEW IF EXISTS vw_fact_sales;

CREATE VIEW vw_fact_sales AS
SELECT
  -- Natural keys
  row_id,
  order_id,
  order_date,
  ship_date,

  -- Date grains
  STR_TO_DATE(CONCAT(YEAR(order_date), '-', LPAD(MONTH(order_date), 2, '0'), '-01'), '%Y-%m-%d') AS `year_month`,

  -- Customer / logistics
  customer_id,
  customer_name,
  segment,
  ship_mode,

  -- Geography
  country,
  region,
  state,
  city,
  market,
  postal_code,

  -- Product
  product_id,
  category,
  sub_category,
  product_name,

  -- Measures
  sales,
  quantity,
  profit,
  shipping_cost,
  discount_rate,          -- normalized to 0..1
  cost_estimated,         -- approx cost = sales - profit
  gross_margin_pct,       -- profit / sales
  unit_price_net,         -- sales / quantity
  order_priority,

  -- Data quality flags
  is_valid_sales,
  is_valid_qty
FROM gss_orders_clean
WHERE is_valid_sales = 1 AND is_valid_qty = 1;

