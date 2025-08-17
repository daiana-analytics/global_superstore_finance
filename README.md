# 📊 Global Superstore — Financial Analytics & BI Project

**Author:** Daiana Beltrán  
**Stack:** MySQL 8 • SQL (ETL, DQ, Modeling, Security) • Power BI • (Optional: Python Forecasting)

📌 **Quick Overview**  
End-to-end **Financial Analytics & BI project** using SQL & Power BI:  
ETL → Star Schema → KPIs → Dashboards → BI Security.  
Simulates **enterprise-grade BI pipeline** for portfolio demonstration.

---

## 🎯 Executive Summary
This project delivers an **end-to-end financial analytics pipeline** with professional BI governance:

- **Robust ETL** (CSV → STAGE → RAW → CLEAN → STAR).
- **Finance KPIs** & dashboard-ready aggregates.
- **Data Quality & Auditing** with issue tracking.
- **Star Schema (FACT + DIM)** optimized for BI.
- **Curated BI schema** with read-only role & contract views.
- **Power BI dashboards** connected via the BI user.

Outcome: A **portfolio-grade BI solution** simulating enterprise standards.

---

## 📂 Scripts & Purpose

| Script | Purpose |
|--------|---------|
| **00_create_database.sql** | Create DB schema `global_superstore_finance` |
| **01_create_stage_table.sql** | STAGE table (CSV import as-is) |
| **02d_build_stage_norm.sql** | Normalize numeric strings |
| **02d_fix_hyphen_decimal.sql** | Fix hyphen-as-decimal anomalies |
| **02e_load_raw_from_stage_norm.sql** | Load RAW table (guarded casts) |
| **03_load_clean_from_raw.sql** | Build CLEAN layer (KPIs + flags) |
| **04_views_dashboard.sql** | Finance & dashboard views |
| **05_data_quality_audit.sql** | DQ framework (etl_runs, dq_metrics, dq_issues) |
| **06_views_fact.sql** | FACT view (valid sales only) |
| **07_views_dimensions.sql** | DIM views (date, product, geo) |
| **08_materialize_star.sql** | Materialize FACT + DIM tables |
| **09_financial_kpis.sql** | KPI views (Revenue, Profit, Margin %, Ticket, Top N, Geo, Monthly) |
| **10_dashboard_views.sql** | Executive, time, product, geo, customer, logistics views |
| **11_admin_and_security.sql** | Performance tuning + basic BI user |
| **12_bi_role_user.sql** | BI Role & User (parametrized, idempotent) |
| **13_bi_schema_and_grants.sql** | Curated BI schema & SELECT grants |
| **14_publish_bi_views.sql** | Publish contract views & optional FACT/DIM |
| **15_verification_tests.sql** | Automated validation of BI user permissions |

---

## 💰 Finance KPIs
From `09_financial_kpis.sql`:

- **Total Revenue** (`vw_kpi_total_revenue`)  
- **Total Profit** (`vw_kpi_total_profit`)  
- **Profit Margin %** (`vw_kpi_profit_margin`)  
- **Avg Ticket Size** (`vw_kpi_avg_ticket`)  
- **Top 10 Products / Customers** by sales  
- **Revenue & Profit by Country**  
- **Monthly Revenue Trend** with profit  

These feed Power BI **cards & time-series visuals**.

---

## 📈 Dashboard Views
From `10_dashboard_views.sql`:

- **Overview** → revenue, profit, margin, avg ticket, etc.  
- **Time series (monthly & quarterly)** with MoM deltas.  
- **Products** → category/subcategory & top 25 by profit.  
- **Geography** → country & region/state aggregations.  
- **Customers** → by segment.  
- **Logistics** → shipping cost, priority, mode.  

Designed for **direct binding to Power BI visuals**.

---

## 🔧 Performance Tuning & Security
From `11_admin_and_security.sql`:
- Global timeout tuning for dashboard queries.
- Optimizer statistics refresh.  
- Creation of **read-only BI user** (`bi_reader`).

From `12–14`:
- **Role & User** (`bi_reader_role`).
- **Curated BI schema** (`global_superstore_bi`).
- **Published BI contract views** (finance, dashboards, FACT & DIM).  

From `15_verification_tests.sql`:
- Automated checks that BI user can only `SELECT` but **cannot** `INSERT/UPDATE/DELETE/CREATE/DROP`.  
- Test results logged in `tmp_bi_verify`.

---

## 🖥️ Power BI Dashboards
Pages suggested:
1. **Executive Summary** (cards + KPIs)  
2. **Trends** (monthly, quarterly, MoM deltas)  
3. **Markets & Regions** (maps + geo charts)  
4. **Customers & Segments** (profitability)  
5. **Products** (top/bottom, categories)  
6. **Logistics** (shipping cost & order priority)  

---

## 🔒 Security Architecture
- **Admin schema**: `global_superstore_finance` (all ETL + STAR)  
- **BI schema**: `global_superstore_bi` (only curated contract views)  
- **Role-based model**: `bi_reader_role` → bound to `bi_reader@%` user.  
- **Principle of least privilege**: BI user = `SELECT` only.  

This separation simulates a **professional enterprise BI deployment**.

---

## ✅ Run Order
1. `00` → `08` (DB, ETL, STAR schema)  
2. `09` → `10` (KPI + Dashboard views)  
3. `11` → `15` (Admin tuning, BI security, publishing, verification)  

---

## 📌 Change Log
- **2025-08-15**: DB, Stage, Stage_Norm, Raw  
- **2025-08-16**: Clean, Dashboard, DQ Audit, Star Schema  
- **2025-08-17**: KPIs, Dashboard Views, Security (Roles, Grants, Publishing, Verification)  

---

## 🏆 Portfolio Value
This repository demonstrates:
- **ETL proficiency** in SQL.  
- **Data Quality & Governance**.  
- **Star schema modeling**.  
- **Enterprise-level BI security**.  
- **BI-ready dashboarding** with Power BI.  

A recruiter or hiring manager will immediately see **professional data engineering + analytics maturity**.
