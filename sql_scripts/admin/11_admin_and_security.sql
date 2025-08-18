-- =====================================================
-- 📂 Script: 11_admin_and_security.sql
-- 📌 Description: Admin, performance tuning & security setup
-- 👩 Author: Daiana Beltrán
-- 📅 Last Updated: 2025-08-17
-- =====================================================

-- =====================================================
-- 🔧 Performance tuning
-- =====================================================

-- Increase wait timeout for long-running dashboard queries
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;

-- Refresh optimizer statistics
ANALYZE TABLE fact_sales;
ANALYZE TABLE dim_product;
ANALYZE TABLE dim_date;
ANALYZE TABLE dim_geo;


-- =====================================================
-- 🔒 Security: create read-only BI user
-- =====================================================

-- Create user for Power BI (read-only)
DROP USER IF EXISTS 'bi_reader'@'%';
CREATE USER 'bi_reader'@'%' IDENTIFIED BY 'StrongPassword123!';

-- Grant read-only access to clean schema and views
GRANT SELECT ON global_superstore_finance.* TO 'bi_reader'@'%';

-- Optional: restrict only to views for BI
-- REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'bi_reader'@'%';
-- GRANT SELECT ON global_superstore_finance.vw_* TO 'bi_reader'@'%';

-- =====================================================
-- 🛡️ Auditing & validation
-- =====================================================

-- Check privileges
SHOW GRANTS FOR 'bi_reader'@'%';

-- Check tables statistics last update
SHOW TABLE STATUS FROM global_superstore_finance;
