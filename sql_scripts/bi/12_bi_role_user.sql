-- =====================================================
-- 📂 Script: 12_bi_role_user.sql
-- 📌 Purpose: Create a read-only BI role and user.
--             (Actual object grants are done in script 13.)
-- 👩 Author: Daiana Beltrán
-- 🗓️ Created: 2025-08-17
-- 🔁 Idempotent: yes (safe to re-run)
-- 🧩 Requires: MySQL 8.0+ (roles supported)
-- =====================================================

/* -----------------------------------------------
   0) Parameters (customize if you want)
------------------------------------------------ */
SET @bi_user := 'bi_reader';     -- login user name
SET @bi_host := '%';             -- host (use '%' for any host)
SET @bi_pass := 'StrongPassword!123';  -- choose your own strong password

/* -----------------------------------------------
   1) Create the role (idempotent)
------------------------------------------------ */
CREATE ROLE IF NOT EXISTS bi_reader_role;

/* -----------------------------------------------
   2) Drop & (re)create the user with password
      (must be done with dynamic SQL when using variables)
------------------------------------------------ */
-- Drop user if exists
SET @sql := CONCAT(
  'DROP USER IF EXISTS ',
  QUOTE(@bi_user), '@', QUOTE(@bi_host)
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Create user
SET @sql := CONCAT(
  'CREATE USER IF NOT EXISTS ',
  QUOTE(@bi_user), '@', QUOTE(@bi_host),
  ' IDENTIFIED BY ', QUOTE(@bi_pass)
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

/* -----------------------------------------------
   3) Attach the role to the user and make it default
------------------------------------------------ */
-- GRANT role to user
SET @sql := CONCAT(
  'GRANT bi_reader_role TO ',
  QUOTE(@bi_user), '@', QUOTE(@bi_host)
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Make it the DEFAULT ROLE (⚠️ use TO, not FOR)
SET @sql := CONCAT(
  'SET DEFAULT ROLE bi_reader_role TO ',
  QUOTE(@bi_user), '@', QUOTE(@bi_host)
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

/* -----------------------------------------------
   4) Quick verification
------------------------------------------------ */
SET @sql := CONCAT(
  'SHOW GRANTS FOR ',
  QUOTE(@bi_user), '@', QUOTE(@bi_host)
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ============== End of script ==================

