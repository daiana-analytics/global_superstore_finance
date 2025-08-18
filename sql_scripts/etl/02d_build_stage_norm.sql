-- =====================================================
-- 📂 Script: 02d_build_stage_norm.sql
-- 📌 Description: Build a normalized STAGE table (no CTEs).
--                 Cleans numeric text and prepares safe numeric strings
--                 for a robust RAW load.
-- 👩 Author: Daiana Beltrán
-- 📅 Created: 2025-08-15
-- =====================================================

USE global_superstore_finance;

-- -----------------------------------------------------
-- 1) Rebuild normalized stage table (copy + basic cleaning)
--    - Keep all original text fields (from CSV-as-is)
--    - Add *_raw columns with non-numeric chars removed
-- -----------------------------------------------------
DROP TABLE IF EXISTS gss_stage_norm;

CREATE TABLE gss_stage_norm AS
SELECT
  -- Original columns (as imported)
  `Row ID`,
  `Order ID`,
  `Order Date`,
  `Ship Date`,
  `Ship Mode`,
  `Customer ID`,
  `Customer Name`,
  `Segment`,
  `Country`,
  `City`,
  `State`,
  `Postal Code`,
  `Market`,
  `Region`,
  `Product ID`,
  `Category`,
  `Sub-Category`,
  `Product Name`,
  `Order Priority`,

  -- Raw numeric text: strip everything except digits, sign, dot, comma
  REGEXP_REPLACE(`Sales`,          '[^0-9,.-]', '') AS sales_raw,
  REGEXP_REPLACE(`Quantity`,       '[^0-9-]',     '') AS quantity_raw,
  REGEXP_REPLACE(`Discount`,       '[^0-9,.-]', '') AS discount_raw,
  REGEXP_REPLACE(`Profit`,         '[^0-9,.-]', '') AS profit_raw,
  REGEXP_REPLACE(`Shipping Cost`,  '[^0-9,.-]', '') AS shipping_raw
FROM gss_orders_stage;

-- -----------------------------------------------------
-- 2) Add *_norm target columns (safe numeric strings)
--    (will be casted later in 02e_load_raw_from_stage_norm.sql)
-- -----------------------------------------------------
ALTER TABLE gss_stage_norm
  ADD COLUMN sales_norm     VARCHAR(64),
  ADD COLUMN quantity_norm  VARCHAR(32),
  ADD COLUMN discount_norm  VARCHAR(32),
  ADD COLUMN profit_norm    VARCHAR(64),
  ADD COLUMN shipping_norm  VARCHAR(64);

-- -----------------------------------------------------
-- 3) Normalize decimal/thousand separators
--    Rule:
--      - If value contains both '.' and ','  -> '.' is thousands, ',' is decimal
--        => remove dots, convert comma to dot
--      - Else                                -> convert comma to dot
-- -----------------------------------------------------
SET SQL_SAFE_UPDATES = 0;

UPDATE gss_stage_norm
SET
  sales_norm = CASE
                 WHEN sales_raw LIKE '%.%,%' THEN REPLACE(REPLACE(sales_raw, '.', ''), ',', '.')
                 ELSE REPLACE(sales_raw, ',', '.')
               END,
  quantity_norm = quantity_raw,
  discount_norm = CASE
                    WHEN discount_raw LIKE '%.%,%' THEN REPLACE(REPLACE(discount_raw, '.', ''), ',', '.')
                    ELSE REPLACE(discount_raw, ',', '.')
                  END,
  profit_norm = CASE
                  WHEN profit_raw LIKE '%.%,%' THEN REPLACE(REPLACE(profit_raw, '.', ''), ',', '.')
                  ELSE REPLACE(profit_raw, ',', '.')
                END,
  shipping_norm = CASE
                    WHEN shipping_raw LIKE '%.%,%' THEN REPLACE(REPLACE(shipping_raw, '.', ''), ',', '.')
                    ELSE REPLACE(shipping_raw, ',', '.')
                  END;

SET SQL_SAFE_UPDATES = 1;

-- -----------------------------------------------------
-- 4) (Optional) Quick validation helpers
--    Un-comment to spot obvious issues while developing.
-- -----------------------------------------------------
-- SELECT
--   COUNT(*)                                                   AS total_rows,
--   SUM(sales_norm    REGEXP '^[+-]?[0-9]+(\\.[0-9]+)?$')      AS ok_sales,
--   SUM(quantity_norm REGEXP '^[+-]?[0-9]+$')                  AS ok_qty,
--   SUM(discount_norm REGEXP '^[+-]?[0-9]+(\\.[0-9]+)?$')      AS ok_discount,
--   SUM(profit_norm   REGEXP '^[+-]?[0-9]+(\\.[0-9]+)?$')      AS ok_profit,
--   SUM(shipping_norm REGEXP '^[+-]?[0-9]+(\\.[0-9]+)?$')      AS ok_shipping
-- FROM gss_stage_norm;

-- SELECT * FROM gss_stage_norm LIMIT 20;

