-- =====================================================
-- 📂 Script: 01_create_stage_table.sql
-- 📌 Description: Creates a STAGE table to import the raw CSV as-is (all text, including Market)
-- 👩 Author: Daiana Beltrán
-- 📅 Created: 2025-08-15
-- =====================================================

USE global_superstore_finance;

DROP TABLE IF EXISTS gss_orders_stage;
CREATE TABLE gss_orders_stage (
  `Row ID`         VARCHAR(20),
  `Order ID`       VARCHAR(30),
  `Order Date`     VARCHAR(20),
  `Ship Date`      VARCHAR(20),
  `Ship Mode`      VARCHAR(50),
  `Customer ID`    VARCHAR(30),
  `Customer Name`  VARCHAR(120),
  `Segment`        VARCHAR(50),
  `Country`        VARCHAR(100),
  `City`           VARCHAR(100),
  `State`          VARCHAR(100),
  `Postal Code`    VARCHAR(20),
  `Market`         VARCHAR(50),
  `Region`         VARCHAR(50),
  `Product ID`     VARCHAR(50),
  `Category`       VARCHAR(50),
  `Sub-Category`   VARCHAR(50),
  `Product Name`   VARCHAR(255),
  `Sales`          VARCHAR(40),
  `Quantity`       VARCHAR(20),
  `Discount`       VARCHAR(20),
  `Profit`         VARCHAR(40),
  `Shipping Cost`  VARCHAR(40),
  `Order Priority` VARCHAR(30)
);


