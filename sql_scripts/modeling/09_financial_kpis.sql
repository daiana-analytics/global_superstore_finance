-- =====================================================
-- 📂 Script: 09_financial_kpis.sql
-- 📌 Description: Create financial KPI views for eCommerce analytics
-- 👩 Author: Daiana Beltrán
-- 📅 Last Updated: 2025-08-17
-- =====================================================

USE global_superstore_finance;

-- =====================================================
-- 💰 KPI 1: Total Revenue (Gross Sales)
-- =====================================================
DROP VIEW IF EXISTS vw_kpi_total_revenue;
CREATE VIEW vw_kpi_total_revenue AS
SELECT 
    SUM(sales) AS total_revenue
FROM fact_sales;

-- =====================================================
-- 💵 KPI 2: Total Profit
-- =====================================================
DROP VIEW IF EXISTS vw_kpi_total_profit;
CREATE VIEW vw_kpi_total_profit AS
SELECT 
    SUM(profit) AS total_profit
FROM fact_sales;

-- =====================================================
-- 📈 KPI 3: Profit Margin %
-- =====================================================
DROP VIEW IF EXISTS vw_kpi_profit_margin;
CREATE VIEW vw_kpi_profit_margin AS
SELECT 
    (SUM(profit) / NULLIF(SUM(sales),0)) * 100 AS profit_margin_pct
FROM fact_sales;

-- =====================================================
-- 🛒 KPI 4: Average Ticket Size (Avg Revenue per Order)
-- =====================================================
DROP VIEW IF EXISTS vw_kpi_avg_ticket;
CREATE VIEW vw_kpi_avg_ticket AS
SELECT 
    AVG(order_sales) AS avg_ticket_size
FROM (
    SELECT 
        order_id,
        SUM(sales) AS order_sales
    FROM fact_sales
    GROUP BY order_id
) AS t;

-- =====================================================
-- ⭐ KPI 5: Top 10 Products by Revenue
-- =====================================================
DROP VIEW IF EXISTS vw_top_products;
CREATE VIEW vw_top_products AS
SELECT 
    p.product_id,
    p.product_name,
    SUM(f.sales) AS total_sales,
    SUM(f.profit) AS total_profit
FROM fact_sales f
JOIN dim_product p 
    ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_sales DESC
LIMIT 10;

-- =====================================================
-- 👥 KPI 6: Top 10 Customers by Revenue
-- =====================================================
DROP VIEW IF EXISTS vw_top_customers;
CREATE VIEW vw_top_customers AS
SELECT 
    customer_id,
    customer_name,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM fact_sales
GROUP BY customer_id, customer_name
ORDER BY total_sales DESC
LIMIT 10;

-- =====================================================
-- 🌍 KPI 7: Revenue & Profit by Country
-- =====================================================
DROP VIEW IF EXISTS vw_revenue_by_country;
CREATE VIEW vw_revenue_by_country AS
SELECT 
    country,
    SUM(sales)  AS total_sales,
    SUM(profit) AS total_profit
FROM fact_sales
GROUP BY country
ORDER BY total_sales DESC;


-- =====================================================
-- 📅 KPI 8: Monthly Revenue Trend
-- =====================================================
DROP VIEW IF EXISTS vw_monthly_revenue;
CREATE VIEW vw_monthly_revenue AS
SELECT 
    d.year,
    d.month,
    CONCAT(d.year,'-',LPAD(d.month,2,'0')) AS `year_month`,
    SUM(f.sales) AS total_sales,
    SUM(f.profit) AS total_profit
FROM fact_sales f
JOIN dim_date d 
    ON f.order_date = d.date
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- =====================================================
-- ✅ End of Script
-- =====================================================
