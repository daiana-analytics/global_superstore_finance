-- =====================================================
-- 📂 Script: 14_publish_bi_views.sql
-- 📌 Purpose: Publish curated BI-facing views (and optional DIM/FACT)
--             into the BI schema, pointing to the canonical sources.
-- 👩 Author: Daiana Beltrán
-- 🗓️ Created: 2025-08-17
-- 🔁 Idempotent: yes (CREATE OR REPLACE VIEW)
-- =====================================================

-- Schemas (adjust if needed)
SET @src_schema := 'global_superstore_finance';
SET @bi_schema  := 'global_superstore_bi';

-- Ensure target schema exists (no-op if already there)
SET @sql := CONCAT(
  'CREATE SCHEMA IF NOT EXISTS `', @bi_schema,
  '` DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_0900_ai_ci'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- -----------------------------------------------------
-- A) List of BI CONTRACT views to publish
-- -----------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_bi_views;
CREATE TEMPORARY TABLE tmp_bi_views (
  id INT AUTO_INCREMENT PRIMARY KEY,
  view_name VARCHAR(128) NOT NULL
);

-- Finance & analytics
INSERT INTO tmp_bi_views(view_name) VALUES
  ('vw_fin_summary'),
  ('vw_sales_by_month'),
  ('vw_profit_by_market'),
  ('vw_profit_by_region'),
  ('vw_top_products_profit'),

  -- Dashboard views
  ('vw_dash_overview'),
  ('vw_dash_time_month'),
  ('vw_dash_time_quarter'),
  ('vw_dash_product_cat'),
  ('vw_dash_product_top25'),
  ('vw_dash_geo_country'),
  ('vw_dash_geo_region_state'),
  ('vw_dash_customer_segment'),
  ('vw_dash_logistics');

-- -----------------------------------------------------
-- B) Optional: expose DIM/FACT for self-service
--     (Comment out any rows you don’t want)
-- -----------------------------------------------------
INSERT INTO tmp_bi_views(view_name) VALUES
  ('dim_date'),
  ('dim_product'),
  ('dim_geo'),
  ('fact_sales');

-- -----------------------------------------------------
-- C) Publish loop via stored procedure (cursor)
--     MySQL requires loops inside stored programs.
-- -----------------------------------------------------
DELIMITER $$

DROP PROCEDURE IF EXISTS publish_bi_views $$
CREATE PROCEDURE publish_bi_views()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE vname VARCHAR(128);

  DECLARE cur CURSOR FOR
    SELECT view_name FROM tmp_bi_views ORDER BY id;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO vname;
    IF done THEN
      LEAVE read_loop;
    END IF;

    SET @sql := CONCAT(
      'CREATE OR REPLACE SQL SECURITY INVOKER VIEW `', @bi_schema, '`.`', vname, '` AS ',
      'SELECT * FROM `', @src_schema, '`.`', vname, '`'
    );
    PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
  END LOOP;
  CLOSE cur;
END $$
DELIMITER ;

CALL publish_bi_views();
DROP PROCEDURE publish_bi_views;

-- -----------------------------------------------------
-- D) Verification
-- -----------------------------------------------------
SELECT 'BI objects published' AS status,
       (SELECT COUNT(*) FROM information_schema.VIEWS
        WHERE TABLE_SCHEMA = @bi_schema) AS bi_views_count;





