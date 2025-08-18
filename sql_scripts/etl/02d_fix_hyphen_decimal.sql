-- =====================================================
-- 📂 Script: 02d_fix_hyphen_decimal.sql
-- 📌 Description: Fix numeric values that use a hyphen as decimal separator (e.g., 2011-90 → 2011.90)
-- 👩 Author: Daiana Beltrán
-- 📅 Created: 2025-08-15
-- =====================================================

USE global_superstore_finance;

SET SQL_SAFE_UPDATES = 0;

UPDATE gss_stage_norm
SET
  sales_norm    = CASE WHEN sales_norm    REGEXP '^[0-9]+-[0-9]+$' THEN REPLACE(sales_norm,    '-', '.') ELSE sales_norm    END,
  discount_norm = CASE WHEN discount_norm REGEXP '^[0-9]+-[0-9]+$' THEN REPLACE(discount_norm, '-', '.') ELSE discount_norm END,
  profit_norm   = CASE WHEN profit_norm   REGEXP '^[0-9]+-[0-9]+$' THEN REPLACE(profit_norm,   '-', '.') ELSE profit_norm   END,
  shipping_norm = CASE WHEN shipping_norm REGEXP '^[0-9]+-[0-9]+$' THEN REPLACE(shipping_norm, '-', '.') ELSE shipping_norm END;

SET SQL_SAFE_UPDATES = 1;

-- Sanity check
-- SELECT
--   SUM(sales_norm    REGEXP '^[0-9]+-[0-9]+$') AS remaining_bad_sales,
--   SUM(discount_norm REGEXP '^[0-9]+-[0-9]+$') AS remaining_bad_discount,
--   SUM(profit_norm   REGEXP '^[0-9]+-[0-9]+$') AS remaining_bad_profit,
--   SUM(shipping_norm REGEXP '^[0-9]+-[0-9]+$') AS remaining_bad_shipping
-- FROM gss_stage_norm;

