-- =====================================================
-- 📂 Script: 05_data_quality_audit.sql
-- 📌 Description: Data Quality (DQ) audit, metrics, and traceability
-- 👩 Author: Daiana Beltrán
-- 📅 Created: 2025-08-15
-- =====================================================

USE global_superstore_finance;

-- =====================================================
-- 0) Control / audit tables (compatible with your schema)
-- =====================================================
CREATE TABLE IF NOT EXISTS etl_runs (
  run_id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  run_ts       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  comment_txt  VARCHAR(255) NULL,
  PRIMARY KEY (run_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS dq_metrics (
  run_id            BIGINT UNSIGNED NOT NULL,
  layer_name        ENUM('stage','raw','clean') NOT NULL,
  rows_total        BIGINT NOT NULL,
  -- extra metrics for CLEAN
  min_order_date    DATE NULL,
  max_order_date    DATE NULL,
  null_sales        BIGINT NULL,
  null_qty          BIGINT NULL,
  null_profit       BIGINT NULL,
  null_ship_cost    BIGINT NULL,
  qty_le_0          BIGINT NULL,
  sales_lt_0        BIGINT NULL,
  discount_oob      BIGINT NULL,  -- out of bounds [0..1]
  PRIMARY KEY (run_id, layer_name),
  CONSTRAINT fk_dq_metrics_run
    FOREIGN KEY (run_id) REFERENCES etl_runs(run_id)
      ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Portable support index (create only if missing)
SET @idx_sql := (
  SELECT IF(
    EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
           WHERE TABLE_SCHEMA = DATABASE()
             AND TABLE_NAME = 'dq_metrics'
             AND INDEX_NAME = 'ix_dq_metrics_layer'),
    'SELECT 1',
    'CREATE INDEX ix_dq_metrics_layer ON dq_metrics(layer_name, run_id)'
  )
);
PREPARE s FROM @idx_sql; EXECUTE s; DEALLOCATE PREPARE s;

-- =====================================================
-- 1) Register a new run
-- =====================================================
INSERT INTO etl_runs (comment_txt)
VALUES ('DQ audit after building dashboard views');
SET @run_id := LAST_INSERT_ID();

-- =====================================================
-- 2) Stage metrics  (insert only if missing for this run)
-- =====================================================
INSERT INTO dq_metrics (run_id, layer_name, rows_total)
SELECT @run_id, 'stage', COALESCE(COUNT(*),0)
FROM gss_orders_stage
WHERE NOT EXISTS (
  SELECT 1 FROM dq_metrics
  WHERE run_id = @run_id AND layer_name = 'stage'
);

-- =====================================================
-- 3) Raw metrics
-- =====================================================
INSERT INTO dq_metrics (run_id, layer_name, rows_total)
SELECT @run_id, 'raw', COALESCE(COUNT(*),0)
FROM gss_orders_raw
WHERE NOT EXISTS (
  SELECT 1 FROM dq_metrics
  WHERE run_id = @run_id AND layer_name = 'raw'
);

-- =====================================================
-- 4) Clean metrics (enriched)
-- =====================================================
INSERT INTO dq_metrics (
  run_id, layer_name, rows_total,
  min_order_date, max_order_date,
  null_sales, null_qty, null_profit, null_ship_cost,
  qty_le_0, sales_lt_0, discount_oob
)
SELECT
  @run_id, 'clean',
  COUNT(*)                                          AS rows_total,
  MIN(order_date)                                   AS min_order_date,
  MAX(order_date)                                   AS max_order_date,
  SUM(sales         IS NULL)                        AS null_sales,
  SUM(quantity      IS NULL)                        AS null_qty,
  SUM(profit        IS NULL)                        AS null_profit,
  SUM(shipping_cost IS NULL)                        AS null_ship_cost,
  SUM(quantity IS NULL OR quantity <= 0)            AS qty_le_0,
  SUM(sales    IS NULL OR sales < 0)                AS sales_lt_0,
  SUM(discount_rate IS NOT NULL AND
      (discount_rate < 0 OR discount_rate > 1))     AS discount_oob
FROM gss_orders_clean
WHERE NOT EXISTS (
  SELECT 1 FROM dq_metrics
  WHERE run_id = @run_id AND layer_name = 'clean'
);

-- =====================================================
-- 5) Issues view (fast drill-down)
-- =====================================================
DROP VIEW IF EXISTS vw_dq_issues;
CREATE VIEW vw_dq_issues AS
SELECT
  row_id, order_id, order_date, customer_id, product_id,
  sales, quantity, profit, shipping_cost, discount_rate,
  CASE WHEN quantity IS NULL OR quantity <= 0 THEN 'QTY_NULL_OR_LE_0' END            AS issue_qty,
  CASE WHEN sales    IS NULL OR sales    <  0 THEN 'SALES_NULL_OR_LT_0' END          AS issue_sales,
  CASE WHEN discount_rate IS NOT NULL AND (discount_rate < 0 OR discount_rate > 1)
       THEN 'DISCOUNT_OUT_OF_BOUNDS' END                                             AS issue_discount,
  CASE WHEN shipping_cost IS NULL THEN 'SHIPPING_NULL' END                           AS issue_ship
FROM gss_orders_clean
WHERE (quantity IS NULL OR quantity <= 0)
   OR (sales    IS NULL OR sales    <  0)
   OR (discount_rate IS NOT NULL AND (discount_rate < 0 OR discount_rate > 1))
   OR (shipping_cost IS NULL);

-- =====================================================
-- 6) Helpful indexes on CLEAN (create-if-missing)
-- =====================================================
-- order_date
SET @sql := (
  SELECT IF(
    EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
           WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='gss_orders_clean'
             AND INDEX_NAME='ix_clean_orddate'),
    'SELECT 1',
    'CREATE INDEX ix_clean_orddate ON gss_orders_clean(order_date)'
  )
); PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- sales
SET @sql := (
  SELECT IF(
    EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
           WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='gss_orders_clean'
             AND INDEX_NAME='ix_clean_sales'),
    'SELECT 1',
    'CREATE INDEX ix_clean_sales ON gss_orders_clean(sales)'
  )
); PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- quantity
SET @sql := (
  SELECT IF(
    EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
           WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='gss_orders_clean'
             AND INDEX_NAME='ix_clean_qty'),
    'SELECT 1',
    'CREATE INDEX ix_clean_qty ON gss_orders_clean(quantity)'
  )
); PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- discount_rate
SET @sql := (
  SELECT IF(
    EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
           WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='gss_orders_clean'
             AND INDEX_NAME='ix_clean_disc'),
    'SELECT 1',
    'CREATE INDEX ix_clean_disc ON gss_orders_clean(discount_rate)'
  )
); PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- =====================================================
-- 7) Executive summary for this run
-- =====================================================
SELECT
  m.run_id, r.run_ts, r.comment_txt,
  m.layer_name, m.rows_total,
  m.min_order_date, m.max_order_date,
  m.null_sales, m.null_qty, m.null_profit, m.null_ship_cost,
  m.qty_le_0, m.sales_lt_0, m.discount_oob
FROM dq_metrics m
JOIN etl_runs r ON r.run_id = m.run_id
WHERE m.run_id = @run_id
ORDER BY FIELD(m.layer_name,'stage','raw','clean');

-- =====================================================
-- 8) Overall status + severity + sample issues
-- =====================================================
SELECT
  CASE
    WHEN (SELECT COALESCE(null_sales,0)+COALESCE(null_qty,0)+COALESCE(qty_le_0,0)+
                 COALESCE(sales_lt_0,0)+COALESCE(discount_oob,0)+COALESCE(null_ship_cost,0)
          FROM dq_metrics
          WHERE run_id=@run_id AND layer_name='clean') > 0
    THEN '⚠️  Issues detected in CLEAN. Please review vw_dq_issues.'
    ELSE '✅  CLEAN passed all critical checks.'
  END AS dq_status;

SELECT
  CASE
    WHEN (SELECT rows_total FROM dq_metrics WHERE run_id=@run_id AND layer_name='clean') = 0
    THEN 'CRITICAL'
    WHEN (SELECT COALESCE(null_sales,0)+COALESCE(null_qty,0)+COALESCE(qty_le_0,0)+
                 COALESCE(sales_lt_0,0)+COALESCE(discount_oob,0)+COALESCE(null_ship_cost,0)
          FROM dq_metrics
          WHERE run_id=@run_id AND layer_name='clean') <= 10
    THEN 'WARN'
    ELSE 'CRITICAL'
  END AS dq_severity;

SELECT * FROM vw_dq_issues LIMIT 20;




