-- =====================================================
-- 📂 Script: 02c_create_raw_table.sql
-- 📌 Description: DDL for RAW table expected by 02e_load_raw_from_stage_norm.sql
-- 👩 Author: Daiana Beltrán
-- 🗓️ Created: 2025-08-19
-- 🔁 Idempotent: Yes (drops & recreates)
-- =====================================================

USE global_superstore_finance;

-- Start clean
DROP TABLE IF EXISTS gss_orders_raw;

-- RAW table: typed fields, still close to source semantics (nullable where appropriate)
CREATE TABLE gss_orders_raw (
  -- Keys & dates
  row_id           INT UNSIGNED           NOT NULL,        -- from `Row ID` (CSV)
  order_id         VARCHAR(30)            NULL,
  order_date       DATE                   NULL,
  ship_date        DATE                   NULL,

  -- Customer & logistics
  ship_mode        VARCHAR(50)            NULL,
  customer_id      VARCHAR(30)            NULL,
  customer_name    VARCHAR(120)           NULL,
  segment          VARCHAR(50)            NULL,
  country          VARCHAR(100)           NULL,
  city             VARCHAR(100)           NULL,
  state            VARCHAR(100)           NULL,
  postal_code      VARCHAR(20)            NULL,
  market           VARCHAR(50)            NULL,
  region           VARCHAR(50)            NULL,

  -- Product
  product_id       VARCHAR(50)            NULL,
  category         VARCHAR(50)            NULL,
  sub_category     VARCHAR(50)            NULL,
  product_name     VARCHAR(255)           NULL,

  -- Measures (typed but still “raw”)
  sales            DECIMAL(14,2)          NULL,
  quantity         INT UNSIGNED           NULL,
  discount         DECIMAL(10,4)          NULL,    -- may be 0–1 or 0–100 (normalized later)
  profit           DECIMAL(14,2)          NULL,
  shipping_cost    DECIMAL(14,2)          NULL,

  -- Other
  order_priority   VARCHAR(30)            NULL,

  -- Constraints & indexes
  PRIMARY KEY (row_id),

  KEY ix_raw_order_date   (order_date),
  KEY ix_raw_ship_date    (ship_date),
  KEY ix_raw_customer     (customer_id),
  KEY ix_raw_product      (product_id),
  KEY ix_raw_geo_country  (country),
  KEY ix_raw_geo_market   (market),
  KEY ix_raw_order_id     (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- (Optional) Smoke test to verify structure
-- DESCRIBE gss_orders_raw;

