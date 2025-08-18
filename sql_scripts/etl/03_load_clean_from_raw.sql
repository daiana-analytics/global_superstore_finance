-- =====================================================
-- 📂 Script: 03_load_clean_from_raw.sql
-- 📌 Description: Build CLEAN table with validated fields and finance KPIs
-- 👩 Author: Daiana Beltrán
-- 🗓️ Created: 2025-08-15
-- =====================================================

USE global_superstore_finance;

-- -----------------------------------------------------
-- 1) Drop & (re)create CLEAN with explicit schema
--    (clear data types + BI-ready columns))
-- -----------------------------------------------------
DROP TABLE IF EXISTS gss_orders_clean;

CREATE TABLE gss_orders_clean (
  -- Keys & dates
  row_id           INT UNSIGNED           NOT NULL PRIMARY KEY,
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

  -- Measures (tal cual + normalizado)
  sales            DECIMAL(14,2)          NULL,
  quantity         INT UNSIGNED           NULL,
  discount         DECIMAL(10,4)          NULL,        -- ⬅️ Conservamos el valor original (0–1 o 0–100)
  discount_rate    DECIMAL(10,4)          NULL,        -- ⬅️ Normalizado a 0–1 para KPIs
  profit           DECIMAL(14,2)          NULL,
  shipping_cost    DECIMAL(14,2)          NULL,
  order_priority   VARCHAR(30)            NULL,        -- ⬅️ Conservamos prioridad para análisis logístico

  -- Validity flags
  is_valid_sales   TINYINT(1)             NOT NULL,
  is_valid_qty     TINYINT(1)             NOT NULL,

  -- Derived finance metrics
  cost_estimated       DECIMAL(14,2)      NULL,        -- aprox. costo = ventas - profit
  gross_margin_pct     DECIMAL(10,4)      NULL,        -- profit / sales
  unit_price_net       DECIMAL(14,4)      NULL,        -- sales / qty
  discount_amount_est  DECIMAL(14,4)      NULL         -- estimación $ del descuento
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- 2) Load data from RAW with cleanups and KPIs
-- -----------------------------------------------------
INSERT INTO gss_orders_clean (
  row_id, order_id, order_date, ship_date,
  ship_mode, customer_id, customer_name, segment, country, city, state, postal_code, market, region,
  product_id, category, sub_category, product_name,
  sales, quantity, discount, discount_rate, profit, shipping_cost, order_priority,
  is_valid_sales, is_valid_qty, cost_estimated, gross_margin_pct, unit_price_net, discount_amount_est
)
SELECT
  -- Keys & dates
  r.row_id,
  r.order_id,
  r.order_date,
  r.ship_date,

  -- Customer & logistics
  NULLIF(r.ship_mode, '')                         AS ship_mode,
  NULLIF(r.customer_id, '')                       AS customer_id,
  TRIM(r.customer_name)                           AS customer_name,
  NULLIF(r.segment, '')                           AS segment,
  NULLIF(r.country, '')                           AS country,
  NULLIF(r.city, '')                              AS city,
  NULLIF(r.state, '')                             AS state,
  NULLIF(r.postal_code, '')                       AS postal_code,
  NULLIF(r.market, '')                            AS market,
  NULLIF(r.region, '')                            AS region,

  -- Product
  NULLIF(r.product_id, '')                        AS product_id,
  NULLIF(r.category, '')                          AS category,
  NULLIF(r.sub_category, '')                      AS sub_category,
  TRIM(r.product_name)                            AS product_name,

  -- Measures (tal cual + normalizado)
  r.sales,
  r.quantity,
  r.discount,
  /* Normalizamos a 0–1:
     - Si viene 0–100 -> dividimos por 100
     - Si ya viene 0–1 -> lo dejamos
  */
  CASE
    WHEN r.discount IS NULL           THEN NULL
    WHEN r.discount > 1               THEN r.discount / 100
    WHEN r.discount BETWEEN 0 AND 1   THEN r.discount
    ELSE NULL
  END                                         AS discount_rate,
  r.profit,
  COALESCE(r.shipping_cost, 0)                AS shipping_cost,
  NULLIF(r.order_priority, '')                AS order_priority,

  -- Validity flags
  CASE WHEN r.sales    IS NOT NULL                 THEN 1 ELSE 0 END AS is_valid_sales,
  CASE WHEN r.quantity IS NOT NULL AND r.quantity > 0 THEN 1 ELSE 0 END AS is_valid_qty,

  -- Derived metrics (seguros ante NULL/0)
  (r.sales - r.profit)                                        AS cost_estimated,
  CASE WHEN r.sales IS NOT NULL AND r.sales <> 0
       THEN r.profit / r.sales
       ELSE NULL END                                          AS gross_margin_pct,
  CASE WHEN r.quantity IS NOT NULL AND r.quantity <> 0
       THEN r.sales / r.quantity
       ELSE NULL END                                          AS unit_price_net,

  -- Estimación del monto de descuento sólo si el rate es razonable (0..0.9)
  CASE
    WHEN r.sales IS NOT NULL
     AND r.discount IS NOT NULL
     AND (CASE WHEN r.discount > 1 THEN r.discount/100 ELSE r.discount END) BETWEEN 0 AND 0.9
    THEN (r.sales / (1 - (CASE WHEN r.discount > 1 THEN r.discount/100 ELSE r.discount END))) - r.sales
    ELSE NULL
  END                                                         AS discount_amount_est
FROM gss_orders_raw AS r;

-- -----------------------------------------------------
-- 3) Índexes to accelerate reporting/Power BI
-- -----------------------------------------------------
CREATE INDEX ix_clean_dates      ON gss_orders_clean (order_date, ship_date);
CREATE INDEX ix_clean_geo        ON gss_orders_clean (country, region, state, city, market);
CREATE INDEX ix_clean_product    ON gss_orders_clean (category, sub_category, product_id);
CREATE INDEX ix_clean_customer   ON gss_orders_clean (customer_id);
CREATE INDEX ix_clean_priority   ON gss_orders_clean (order_priority);
CREATE INDEX ix_clean_flags      ON gss_orders_clean (is_valid_sales, is_valid_qty);


