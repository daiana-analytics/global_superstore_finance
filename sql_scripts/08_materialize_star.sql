-- =====================================================
-- 📂 Script: 08_materialize_star.sql
-- 📌 Purpose: Materialize the star schema (DIM + FACT tables)
--            from the previously built views to improve BI performance.
-- 👩 Author: Daiana Beltrán
-- 🗓️ Created: 2025-08-16
-- 🔁 Idempotent: Yes (drops & rebuilds tables)
-- ⚙️ Engine/Charset: InnoDB / utf8mb4
-- =====================================================

USE global_superstore_finance;

-- -----------------------------------------------------
-- 0) Session tweaks (safe) – helps if vw_dim_date is recursive
-- -----------------------------------------------------
SET SESSION cte_max_recursion_depth = 20000;

START TRANSACTION;

-- =====================================================
-- 1) DATE DIM (materialize from vw_dim_date)
--    PK = date (natural key)
-- =====================================================
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
  `date`           DATE        NOT NULL,
  `year`           SMALLINT    NOT NULL,
  `quarter`        TINYINT     NOT NULL,
  `month`          TINYINT     NOT NULL,
  `year_month_key` CHAR(7)     NOT NULL,   -- e.g. 2014-12
  `month_name`     VARCHAR(12) NOT NULL,
  `iso_week`       TINYINT     NOT NULL,
  `day_of_month`   TINYINT     NOT NULL,
  `day_name`       VARCHAR(10) NOT NULL,
  `is_business_day` TINYINT(1) NOT NULL,
  PRIMARY KEY (`date`),
  KEY ix_dim_date_year_month (`year`, `month`),
  KEY ix_dim_date_ym_key (`year_month_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO dim_date
SELECT
  `date`, `year`, `quarter`, `month`, `year_month_key`,
  `month_name`, `iso_week`, `day_of_month`, `day_name`, `is_business_day`
FROM vw_dim_date;

-- =====================================================
-- 2) PRODUCT DIM (one row per product_id)
--    PK = product_id
--    (Fix: GROUP BY product_id to avoid duplicates)
-- =====================================================
DROP TABLE IF EXISTS dim_product;

CREATE TABLE dim_product (
  product_id   VARCHAR(50)  NOT NULL,
  product_name VARCHAR(255) NOT NULL,
  category     VARCHAR(50)  NOT NULL,
  sub_category VARCHAR(50)  NOT NULL,
  PRIMARY KEY (product_id),
  KEY ix_dim_product_cat (category, sub_category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO dim_product (product_id, product_name, category, sub_category)
SELECT
  product_id,
  MIN(TRIM(product_name)) AS product_name,
  MIN(category)           AS category,
  MIN(sub_category)       AS sub_category
FROM vw_dim_product
GROUP BY product_id;

-- =====================================================
-- 3) GEO DIM (granular composite PK incl. market + postal_code)
--    PK = (country, region, state, city, market, postal_code)
--    (Fix: include postal_code + market to avoid duplicate PK)
-- =====================================================
DROP TABLE IF EXISTS dim_geo;

CREATE TABLE dim_geo (
  country     VARCHAR(100) NOT NULL,
  region      VARCHAR(50)  NOT NULL,
  state       VARCHAR(100) NOT NULL,
  city        VARCHAR(100) NOT NULL,
  market      VARCHAR(50)  NOT NULL,
  postal_code VARCHAR(20)  NOT NULL,
  PRIMARY KEY (country, region, state, city, market, postal_code),
  KEY ix_dim_geo_country_region (country, region),
  KEY ix_dim_geo_state_city (state, city),
  KEY ix_dim_geo_market (market)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO dim_geo (country, region, state, city, market, postal_code)
SELECT
  country,
  region,
  state,
  city,
  market,
  COALESCE(postal_code, '') AS postal_code
FROM vw_dim_geo;

-- =====================================================
-- 4) FACT SALES (materialize from vw_fact_sales)
--    Natural degenerate keys: row_id, order_id
--    Foreign-keyable columns present for joins (order_date, product_id, geo fields)
-- =====================================================
DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales (
  -- Natural keys / degenerate dims
  row_id        INT UNSIGNED     NOT NULL,
  order_id      VARCHAR(30)      NOT NULL,

  -- Date grains
  order_date    DATE             NOT NULL,
  ship_date     DATE             NULL,

  -- Customer & segmentation (denormalized; keep what BI needs)
  customer_id   VARCHAR(30)      NULL,
  customer_name VARCHAR(120)     NULL,
  segment       VARCHAR(50)      NULL,

  -- Geo (for joining to dim_geo if needed)
  country       VARCHAR(100)     NULL,
  region        VARCHAR(50)      NULL,
  state         VARCHAR(100)     NULL,
  city          VARCHAR(100)     NULL,
  market        VARCHAR(50)      NULL,

  -- Product dim key
  product_id    VARCHAR(50)      NULL,

  -- Business measures
  sales         DECIMAL(14,2)    NULL,
  quantity      INT              NULL,
  profit        DECIMAL(14,2)    NULL,
  shipping_cost DECIMAL(14,2)    NULL,
  discount_rate DECIMAL(10,4)    NULL,
  cost_estimated   DECIMAL(14,2) NULL,
  gross_margin_pct DECIMAL(10,4) NULL,
  unit_price_net   DECIMAL(14,4) NULL,

  -- Logistics
  order_priority VARCHAR(30)     NULL,

  -- Data quality flags
  is_valid_sales TINYINT(1)      NOT NULL,
  is_valid_qty   TINYINT(1)      NOT NULL,

  PRIMARY KEY (row_id),
  KEY ix_fact_order_date (order_date),
  KEY ix_fact_product    (product_id),
  KEY ix_fact_geo_cr     (country, region),
  KEY ix_fact_profit     (profit),
  KEY ix_fact_sales_amt  (sales)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO fact_sales (
  row_id, order_id,
  order_date, ship_date,
  customer_id, customer_name, segment,
  country, region, state, city, market,
  product_id,
  sales, quantity, profit, shipping_cost, discount_rate,
  cost_estimated, gross_margin_pct, unit_price_net,
  order_priority,
  is_valid_sales, is_valid_qty
)
SELECT
  row_id, order_id,
  order_date, ship_date,
  customer_id, customer_name, segment,
  country, region, state, city, market,
  product_id,
  sales, quantity, profit, shipping_cost, discount_rate,
  cost_estimated, gross_margin_pct, unit_price_net,
  order_priority,
  is_valid_sales, is_valid_qty
FROM vw_fact_sales;

COMMIT;

-- =====================================================
-- 5) Optional: update statistics (helps the optimizer)
-- =====================================================
ANALYZE TABLE dim_date, dim_product, dim_geo, fact_sales;

-- =====================================================
-- 6) Quick smoke tests (peek small samples)
-- =====================================================
SELECT * FROM dim_date    ORDER BY `date`    LIMIT 3;
SELECT * FROM dim_product ORDER BY product_id LIMIT 3;
SELECT * FROM dim_geo     LIMIT 3;
SELECT * FROM fact_sales  LIMIT 3;

-- End of script

