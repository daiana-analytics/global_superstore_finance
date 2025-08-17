-- =====================================================
-- 📂 Script: 13_bi_schema_and_grants.sql
-- 📌 Purpose: Create a curated BI schema and grant read-only access to the BI role.
-- 👩 Author: Daiana Beltrán
-- 🗓️ Created: 2025-08-17
-- 🔁 Idempotent: yes (safe to re-run)
-- 🧩 Requires: MySQL 8.0+ (roles recommended)
-- =====================================================

-- Source schema (where your star schema + views live)
SET @src_schema := 'global_superstore_finance';

-- Curated BI schema (only safe, consumable objects)
SET @bi_schema  := 'global_superstore_bi';

-- Helper to escape backticks in identifiers
SET @esc_bi_schema  := REPLACE(@bi_schema,  '`', '``');
SET @esc_src_schema := REPLACE(@src_schema, '`', '``');

-- -----------------------------------------------------
-- 1) Create the BI schema (no-op if it already exists)
-- -----------------------------------------------------
SET @sql := CONCAT(
  'CREATE SCHEMA IF NOT EXISTS `', @esc_bi_schema, '` ',
  'DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_0900_ai_ci'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- -----------------------------------------------------
-- 2) Ensure the BI role exists (in case script 12 wasn’t run)
-- -----------------------------------------------------
CREATE ROLE IF NOT EXISTS bi_reader_role;

-- -----------------------------------------------------
-- 3) Grant read-only access on the BI schema to the BI role
-- -----------------------------------------------------
SET @sql := CONCAT(
  'GRANT SELECT ON `', @esc_bi_schema, '`.* TO bi_reader_role'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- (Optional fallback) If your server does NOT support roles,
-- uncomment and adapt the line below to grant directly to the user:
-- GRANT SELECT ON `global_superstore_bi`.* TO 'bi_reader'@'%';

-- -----------------------------------------------------
-- 4) Quick verification
--    (a) Show grants for the role
--    (b) If the BI user exists, show its grants too
--    (c) List objects in the BI schema
-- -----------------------------------------------------
-- (a)
SHOW GRANTS FOR `bi_reader_role`;

-- (b) This will error if the user doesn’t exist; run it only if you ya creaste el user.
-- SHOW GRANTS FOR 'bi_reader'@'%';

-- (c)
SET @sql := CONCAT('SHOW FULL TABLES FROM `', @esc_bi_schema, '`');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

