-- =====================================================
-- 📂 Script: 15_verification_tests.sql
-- 📌 Purpose: Validate that the BI user has read-only access
--             on the curated BI schema.
-- 👩 Author: Daiana Beltrán
-- 🗓️ Created: 2025-08-17
-- 🔁 Idempotent: yes (uses temporary objects only)
-- =====================================================

-- Adjust if you changed schema or user names
SET @bi_schema := 'global_superstore_bi';

-- Use a safe session environment
SET SESSION sql_notes = 1;
SET SESSION sql_warnings = 1;

-- -----------------------------------------------------
-- Result capture table (temporary, auto-dropped)
-- -----------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS tmp_bi_verify;
CREATE TEMPORARY TABLE tmp_bi_verify (
  step_id      INT AUTO_INCREMENT PRIMARY KEY,
  test_name    VARCHAR(120),
  expected     ENUM('ALLOW','DENY') NOT NULL,
  outcome      ENUM('OK','FAILED','ERROR') NOT NULL,
  sql_text     TEXT,
  error_code   INT NULL,
  error_msg    TEXT NULL,
  executed_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- Helper procedure: runs a dynamic SQL and records result
-- p_expect = 'ALLOW' if we expect it to succeed
--          = 'DENY'  if we expect it to fail
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS bi_run_step;
DELIMITER $$
CREATE PROCEDURE bi_run_step(IN p_name VARCHAR(120), IN p_sql TEXT, IN p_expect ENUM('ALLOW','DENY'))
BEGIN
  DECLARE v_err INT DEFAULT NULL;
  DECLARE v_msg TEXT DEFAULT NULL;
  DECLARE v_ok  TINYINT DEFAULT 1;

  -- Capture any exception
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  BEGIN
    SET v_ok := 0;
    GET DIAGNOSTICS CONDITION 1 v_err = MYSQL_ERRNO, v_msg = MESSAGE_TEXT;
  END;

  -- Execute dynamic SQL
  SET @dyn := p_sql;
  PREPARE s FROM @dyn;
  EXECUTE s;
  DEALLOCATE PREPARE s;

  -- Evaluate outcome vs expectation
  IF p_expect = 'ALLOW' THEN
    IF v_ok = 1 THEN
      INSERT INTO tmp_bi_verify(test_name, expected, outcome, sql_text)
      VALUES (p_name, 'ALLOW', 'OK', p_sql);
    ELSE
      INSERT INTO tmp_bi_verify(test_name, expected, outcome, sql_text, error_code, error_msg)
      VALUES (p_name, 'ALLOW', 'ERROR', p_sql, v_err, v_msg);
    END IF;
  ELSE
    -- Expect DENY: success means a problem; error means correct
    IF v_ok = 1 THEN
      INSERT INTO tmp_bi_verify(test_name, expected, outcome, sql_text)
      VALUES (p_name, 'DENY', 'FAILED', p_sql);     -- should not have succeeded
    ELSE
      INSERT INTO tmp_bi_verify(test_name, expected, outcome, sql_text, error_code, error_msg)
      VALUES (p_name, 'DENY', 'OK', p_sql, v_err, v_msg); -- denied as expected
    END IF;
  END IF;
END$$
DELIMITER ;

-- -----------------------------------------------------
-- Test set
-- NOTE: Prefer running with a connection as 'bi_reader'
-- -----------------------------------------------------

-- ✅ Read must be allowed
CALL bi_run_step(
  'SELECT from BI view',
  CONCAT('SELECT * FROM ', @bi_schema, '.vw_sales_by_month LIMIT 5'),
  'ALLOW'
);

-- ❌ INSERT should be denied (view not updatable / no privileges)
CALL bi_run_step(
  'INSERT into BI view (expect DENY)',
  CONCAT('INSERT INTO ', @bi_schema, '.vw_sales_by_month SELECT * FROM ', @bi_schema, '.vw_sales_by_month LIMIT 0'),
  'DENY'
);

-- ❌ UPDATE should be denied
CALL bi_run_step(
  'UPDATE BI view (expect DENY)',
  CONCAT('UPDATE ', @bi_schema, '.vw_dash_overview SET total_revenue = total_revenue WHERE 1=0'),
  'DENY'
);

-- ❌ DELETE should be denied
CALL bi_run_step(
  'DELETE on BI view (expect DENY)',
  CONCAT('DELETE FROM ', @bi_schema, '.vw_dash_product_top25 WHERE 1=0'),
  'DENY'
);

-- ❌ CREATE VIEW in BI schema should be denied (no CREATE VIEW)
CALL bi_run_step(
  'CREATE VIEW in BI schema (expect DENY)',
  CONCAT('CREATE VIEW ', @bi_schema, '.tmp__bi_smoke AS SELECT 1 AS x'),
  'DENY'
);

-- ❌ DROP VIEW in BI schema should be denied
CALL bi_run_step(
  'DROP VIEW in BI schema (expect DENY)',
  CONCAT('DROP VIEW ', @bi_schema, '.vw_dash_overview'),
  'DENY'
);

-- Cleanup in case the previous CREATE somehow succeeded (should not)
-- This block won’t error if the view doesn’t exist.
DROP VIEW IF EXISTS global_superstore_bi.tmp__bi_smoke;

-- -----------------------------------------------------
-- Report
-- -----------------------------------------------------
SELECT
  step_id,
  test_name,
  expected,
  outcome,
  error_code,
  error_msg
FROM tmp_bi_verify
ORDER BY step_id;

-- Optional: show grants of the BI user (run with admin)
-- SHOW GRANTS FOR 'bi_reader'@'%';

-- Cleanup helper
DROP PROCEDURE IF EXISTS bi_run_step;

-- End of script
