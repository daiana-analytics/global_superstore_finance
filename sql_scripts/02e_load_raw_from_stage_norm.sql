-- =====================================================
-- 📂 Script: 02e_load_raw_from_stage_norm.sql
-- 📌 Description: Robust load of RAW from normalized STAGE (handles strict mode & edge cases)
-- 👩 Author: Daiana Beltrán
-- 📅 Created: 2025-08-15
-- =====================================================

USE global_superstore_finance;

-- Guard: assumes gss_orders_raw was created earlier
-- (If not, create it with the appropriate schema before running this script.)

-- 0) Temporarily relax STRICT mode (restored at the end)
SET @OLD_SQL_MODE := @@SESSION.sql_mode;
SET SESSION sql_mode = REPLACE(REPLACE(@@SESSION.sql_mode, 'STRICT_TRANS_TABLES', ''), 'STRICT_ALL_TABLES', '');

-- 1) Clear RAW
TRUNCATE TABLE gss_orders_raw;

-- 2) Insert with guarded CASTs (validated by REGEXP)
INSERT INTO gss_orders_raw (
  row_id, order_id, order_date, ship_date, ship_mode,
  customer_id, customer_name, segment, country, city, state, postal_code,
  market, region, product_id, category, sub_category, product_name,
  sales, quantity, discount, profit, shipping_cost, order_priority
)
SELECT
  CAST(`Row ID` AS UNSIGNED) AS row_id,
  `Order ID`                  AS order_id,
  STR_TO_DATE(`Order Date`, '%d-%m-%Y') AS order_date,  -- Change to '%m/%d/%Y' if your CSV uses slash
  STR_TO_DATE(`Ship Date`,  '%d-%m-%Y') AS ship_date,
  NULLIF(`Ship Mode`, '')   AS ship_mode,
  NULLIF(`Customer ID`, '') AS customer_id,
  TRIM(`Customer Name`)     AS customer_name,
  NULLIF(`Segment`, '')     AS segment,
  NULLIF(`Country`, '')     AS country,
  NULLIF(`City`, '')        AS city,
  NULLIF(`State`, '')       AS state,
  NULLIF(`Postal Code`, '') AS postal_code,
  NULLIF(`Market`, '')      AS market,
  NULLIF(`Region`, '')      AS region,
  NULLIF(`Product ID`, '')  AS product_id,
  NULLIF(`Category`, '')    AS category,
  NULLIF(`Sub-Category`, '') AS sub_category,
  TRIM(`Product Name`)      AS product_name,

  CASE WHEN sales_norm    REGEXP '^-?[0-9]+(\\.[0-9]+)?$' THEN CAST(sales_norm    AS DECIMAL(14,2)) ELSE NULL END AS sales,
  CASE WHEN quantity_norm REGEXP '^-?[0-9]+$'             THEN CAST(quantity_norm AS UNSIGNED)      ELSE NULL END AS quantity,
  CASE WHEN discount_norm REGEXP '^-?[0-9]+(\\.[0-9]+)?$' THEN CAST(discount_norm AS DECIMAL(10,4)) ELSE NULL END AS discount,
  CASE WHEN profit_norm   REGEXP '^-?[0-9]+(\\.[0-9]+)?$' THEN CAST(profit_norm   AS DECIMAL(14,2)) ELSE NULL END AS profit,
  CASE WHEN shipping_norm REGEXP '^-?[0-9]+(\\.[0-9]+)?$' THEN CAST(shipping_norm AS DECIMAL(14,2)) ELSE NULL END AS shipping_cost,

  NULLIF(`Order Priority`, '') AS order_priority
FROM gss_stage_norm;

-- 3) Restore SQL mode
SET SESSION sql_mode = @OLD_SQL_MODE;

-- 4) Quick validation (optional)
-- SELECT COUNT(*) AS total_rows FROM gss_orders_raw;
-- SELECT SUM(sales IS NULL) AS null_sales,
--        SUM(quantity IS NULL) AS null_qty,
--        SUM(discount IS NULL) AS null_discount,
--        SUM(profit IS NULL) AS null_profit,
--        SUM(shipping_cost IS NULL) AS null_shipping
-- FROM gss_orders_raw;


