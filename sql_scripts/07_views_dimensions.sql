-- =====================================================
-- 📂 Script: 07_views_dimensions.sql
-- 📌 Description: Lightweight DIMENSION views (date, product, geo)
-- 👩 Author: Daiana Beltrán
-- 📅 Created: 2025-08-16
-- =====================================================

USE global_superstore_finance;

-- -----------------------------------------
-- 1) Date dimension (from min to max date)
-- -----------------------------------------
DROP VIEW IF EXISTS vw_dim_date;

CREATE VIEW vw_dim_date AS
WITH RECURSIVE bounds AS (
  SELECT
    COALESCE(MIN(order_date), DATE('2011-01-01')) AS min_d,
    COALESCE(MAX(order_date), DATE('2014-12-31')) AS max_d
  FROM gss_orders_clean
  WHERE order_date IS NOT NULL
),
cal AS (
  SELECT min_d AS d, max_d FROM bounds
  UNION ALL
  SELECT DATE_ADD(d, INTERVAL 1 DAY), max_d
  FROM cal
  WHERE d < max_d
)
SELECT
  d AS `date`,
  YEAR(d)       AS `year`,
  QUARTER(d)    AS `quarter`,
  MONTH(d)      AS `month`,
  DATE_FORMAT(d, '%Y-%m') AS `year_month_key`,
  DATE_FORMAT(d, '%b')    AS `month_name`,
  WEEK(d, 3)    AS `iso_week`,
  DAY(d)        AS `day_of_month`,
  DAYNAME(d)    AS `day_name`,
  CASE WHEN DAYOFWEEK(d) IN (1,7) THEN 0 ELSE 1 END AS `is_business_day`
FROM cal;

-- -----------------------------------------
-- 2) Product dimension
-- -----------------------------------------
DROP VIEW IF EXISTS vw_dim_product;

CREATE VIEW vw_dim_product AS
SELECT DISTINCT
  product_id,
  TRIM(product_name) AS product_name,
  category,
  sub_category
FROM gss_orders_clean
WHERE product_id IS NOT NULL;

-- -----------------------------------------
-- 3) Geography dimension
-- -----------------------------------------
DROP VIEW IF EXISTS vw_dim_geo;

CREATE VIEW vw_dim_geo AS
SELECT DISTINCT
  country,
  region,
  state,
  city,
  market,
  postal_code
FROM gss_orders_clean
WHERE country IS NOT NULL;


