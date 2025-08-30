← Back to: [Detailed README](./README.md)

# 📘 KPI Dictionary (SQL ↔ DAX)

This document aligns **business definitions**, **DAX measures** (Power BI), and **SQL lineage** (contract views) so stakeholders and engineers share the same source of truth.

> **Grain:** Unless noted, all KPIs aggregate at the visual filter context (e.g., Year/Month, Segment, Category).

---

## 1) Revenue & Profit

| KPI | Business definition | DAX (measure) | SQL lineage (view.field) | Grain / Notes |
|---|---|---|---|---|
| **Sales Total** | Total billed revenue in the selected context. | `Sales Total = SUM('Fact Sales'[sales])` | e.g. `global_superstore_bi.vw_kpi_total_revenue.revenue` | Additivity: fully additive. |
| **Profit Total** | Gross profit in absolute terms. | `Profit Total = SUM('Fact Sales'[profit])` | e.g. `global_superstore_bi.vw_kpi_total_profit.profit` | Depends on cost fields consistency. |
| **Gross Margin %** | Profit as a % of Sales. | `Gross Margin % = DIVIDE([Profit Total],[Sales Total],0)` | e.g. `global_superstore_bi.vw_kpi_profit_margin.margin_pct` | Use DIVIDE to avoid /0. |

---

## 2) Price, Ticket & Discount

| KPI | Business definition | DAX (measure) | SQL lineage | Grain / Notes |
|---|---|---|---|---|
| **Avg Ticket** | Average revenue per order. | `Avg Ticket = DIVIDE([Sales Total],[Orders])` | e.g. `...vw_kpi_avg_ticket.avg_ticket` | Semi-additive; use at order-level contexts. |
| **Avg Net Unit Price** | Average net price per unit. | `Avg Net Unit Price = DIVIDE([Sales Total],[Quantity Total])` | derived | Sensitive to mix. |
| **Weighted Discount %** | Discount weighted by sales volume. | <code>Discount % Weighted = DIVIDE( SUMX('Fact Sales','Fact Sales'[sales]*'Fact Sales'[discount_rate]), [Sales Total] )</code> | e.g. `...vw_kpi_discount_weighted.discount_wt_pct` | Prefer this (not the simple average). |

---

## 3) Customers (Acquisition vs. Retention)

| KPI | Business definition | DAX (measure) | SQL lineage | Grain / Notes |
|---|---|---|---|---|
| **Customers** | Distinct customers in filter. | `Customers = DISTINCTCOUNT('Fact Sales'[customer_id])` | e.g. `...vw_customers.customers` | — |
| **New Customers** | First purchase date falls **inside** the selected period. | `New Customers = CALCULATE( DISTINCTCOUNT('Dim Customer'[customer_id]), TREATAS(VALUES('Dim Date'[date]), 'Dim Customer'[First Purchase Date]) )` | e.g. `...vw_customers.new_customers` | Requires correct `First Purchase Date`. |
| **Returning Customers** | Customers − New Customers. | `Returning Customers = [Customers] - [New Customers]` | e.g. `...vw_customers.returning_customers` | — |
| **Revenue New Customers** | Sales from customers whose first purchase is in period. | see DAX above w/ `TREATAS` | e.g. `...vw_revenue.new_customers_revenue` | Used for **Revenue Mix** visual. |
| **Revenue Returning Customers** | Sales − Revenue New Customers. | `Revenue Returning Customers = [Sales Total] - [Revenue New Customers]` | e.g. `...vw_revenue.returning_customers_revenue` | — |
| **Repeat Rate %** | Returning / Customers. | `Repeat Rate % = DIVIDE([Returning Customers],[Customers])` | e.g. `...vw_customers.repeat_rate_pct` | — |

---

## 4) Time Intelligence

| KPI | Business definition | DAX (measure) | SQL lineage | Grain / Notes |
|---|---|---|---|---|
| **Sales LM** | Sales last month (relative to current filter). | `Sales LM = CALCULATE([Sales Total], DATEADD('Dim Date'[date],-1,MONTH))` | e.g. `...vw_time.sales_lm` | Relies on complete date table. |
| **Sales LY** | Sales last year. | `Sales LY = CALCULATE([Sales Total], DATEADD('Dim Date'[date],-1,YEAR))` | e.g. `...vw_time.sales_ly` | — |
| **Sales MoM %** | (Sales − LM) / LM. | `Sales MoM % = DIVIDE([Sales Total]-[Sales LM],[Sales LM])` | e.g. `...vw_time.sales_mom_pct` | Prefer **safe** % below. |
| **Sales YoY %** | (Sales − LY) / LY. | `Sales YoY % = DIVIDE([Sales Total]-[Sales LY],[Sales LY])` | e.g. `...vw_time.sales_yoy_pct` | Prefer **safe** % below. |
| **Safe % vs LM** | Robust MoM % (returns 0 if denom=0). | `Safe % vs LM = DIVIDE([Sales Total]-[Sales LM],[Sales LM],0)` | — | Recommended for cards. |
| **Safe % vs LY** | Robust YoY % (returns 0 if denom=0). | `Safe % vs LY = DIVIDE([Sales Total]-[Sales LY],[Sales LY],0)` | — | — |
| **Sales YTD** | Year-to-date total. | `Sales YTD = TOTALYTD([Sales Total],'Dim Date'[date])` | e.g. `...vw_time.sales_ytd` | Mark date table as **Date table**. |

---

## 5) Shipping & Operations

| KPI | Business definition | DAX (measure) | SQL lineage | Grain / Notes |
|---|---|---|---|---|
| **Shipping Cost Total** | Total shipping cost. | `Shipping Cost Total = SUM('Fact Sales'[shipping_cost])` | e.g. `...vw_shipping.shipping_cost_total` | — |
| **Shipping % Sales** | Shipping cost as % of sales. | `Shipping % Sales = DIVIDE([Shipping Cost Total],[Sales Total])` | e.g. `...vw_shipping.shipping_pct_sales` | Use as **burden** indicator. |
| **Shipping Cost per Order** | Average shipping per order. | `Shipping Cost per Order = DIVIDE([Shipping Cost Total],[Orders])` | e.g. `...vw_shipping.shipping_cost_per_order` | Compare across ship modes. |
| **Lead Time (days)** | Avg days from order to ship. | <code>Lead Time (days) = AVERAGEX('Fact Sales', DATEDIFF('Fact Sales'[order_date],'Fact Sales'[ship_date],DAY))</code> | e.g. `...vw_shipping.lead_time_days` | SLA target ≤ **4 days**. |
| **Sales by Ship Date** | Sales re-evaluated on ship_date. | <code>Sales by Ship Date = CALCULATE([Sales Total], USERELATIONSHIP('Fact Sales'[ship_date],'Dim Date'[date]))</code> | e.g. `...vw_shipping.sales_by_ship_date` | Enables **Orders vs Shipments** chart. |

---

## 6) Concentration

| KPI | Business definition | DAX (measure) | SQL lineage | Grain / Notes |
|---|---|---|---|---|
| **Top 10 Customers %** | Share of sales from top-10 customers. | `TOPN + DIVIDE([Top Sales],[Sales Total])` | e.g. `...vw_concentration.top10_cust_pct` | Risk of dependency. |
| **Top 10 Products %** | Share of sales from top-10 products. | `TOPN + DIVIDE([Top Sales],[Sales Total])` | e.g. `...vw_concentration.top10_prod_pct` | Risk of dependency. |

---

### Naming & Governance
- **Prefix measures** by theme (e.g., *TIME*, *SHIPPING*) if needed.
- **Document assumptions** (e.g., sales are net of discount).
- **Use contract views** in `global_superstore_bi` for stable Power BI binding.
