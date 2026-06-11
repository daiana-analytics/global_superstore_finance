markdown
← Volver a: [README detallado](./README.md)

# 📘 Diccionario de KPIs (SQL ↔ DAX)

Este documento alinea las **definiciones de negocio**, las **medidas DAX** utilizadas en Power BI y el **origen SQL** de cada indicador.  
El objetivo es que tanto usuarios de negocio como perfiles técnicos trabajen con una misma fuente de verdad.

> **Nivel de agregación:** salvo que se indique lo contrario, los KPIs se calculan según el contexto de filtro del visual, por ejemplo: año, mes, segmento, categoría o región.

---

## 1) Ventas y rentabilidad

| KPI | Definición de negocio | DAX (medida) | Origen SQL (vista.campo) | Nivel / Notas |
|---|---|---|---|---|
| **Sales Total** | Total de ventas facturadas en el contexto seleccionado. | `Sales Total = SUM('Fact Sales'[sales])` | Ej.: `global_superstore_bi.vw_kpi_total_revenue.revenue` | Indicador totalmente aditivo. |
| **Profit Total** | Ganancia bruta en términos absolutos. | `Profit Total = SUM('Fact Sales'[profit])` | Ej.: `global_superstore_bi.vw_kpi_total_profit.profit` | Depende de la consistencia de los campos de costo y ganancia. |
| **Gross Margin %** | Ganancia expresada como porcentaje de las ventas. | `Gross Margin % = DIVIDE([Profit Total],[Sales Total],0)` | Ej.: `global_superstore_bi.vw_kpi_profit_margin.margin_pct` | Se usa `DIVIDE` para evitar errores por división entre cero. |

---

## 2) Precio, ticket y descuentos

| KPI | Definición de negocio | DAX (medida) | Origen SQL | Nivel / Notas |
|---|---|---|---|---|
| **Avg Ticket** | Ingreso promedio por orden. | `Avg Ticket = DIVIDE([Sales Total],[Orders])` | Ej.: `...vw_kpi_avg_ticket.avg_ticket` | Indicador semi-aditivo. Conviene analizarlo a nivel de orden o agregaciones controladas. |
| **Avg Net Unit Price** | Precio neto promedio por unidad vendida. | `Avg Net Unit Price = DIVIDE([Sales Total],[Quantity Total])` | Derivado | Es sensible al mix de productos vendidos. |
| **Weighted Discount %** | Descuento ponderado por volumen de ventas. | <code>Discount % Weighted = DIVIDE( SUMX('Fact Sales','Fact Sales'[sales]*'Fact Sales'[discount_rate]), [Sales Total] )</code> | Ej.: `...vw_kpi_discount_weighted.discount_wt_pct` | Es preferible usar descuento ponderado en lugar de promedio simple. |

---

## 3) Clientes: adquisición y retención

| KPI | Definición de negocio | DAX (medida) | Origen SQL | Nivel / Notas |
|---|---|---|---|---|
| **Customers** | Cantidad de clientes únicos dentro del filtro aplicado. | `Customers = DISTINCTCOUNT('Fact Sales'[customer_id])` | Ej.: `...vw_customers.customers` | — |
| **New Customers** | Clientes cuya primera compra ocurre dentro del período seleccionado. | `New Customers = CALCULATE( DISTINCTCOUNT('Dim Customer'[customer_id]), TREATAS(VALUES('Dim Date'[date]), 'Dim Customer'[First Purchase Date]) )` | Ej.: `...vw_customers.new_customers` | Requiere que el campo `First Purchase Date` esté correctamente calculado. |
| **Returning Customers** | Clientes recurrentes: total de clientes menos clientes nuevos. | `Returning Customers = [Customers] - [New Customers]` | Ej.: `...vw_customers.returning_customers` | — |
| **Revenue New Customers** | Ventas generadas por clientes cuya primera compra ocurre dentro del período seleccionado. | Ver lógica DAX con `TREATAS` | Ej.: `...vw_revenue.new_customers_revenue` | Se utiliza para el visual de mix de ingresos. |
| **Revenue Returning Customers** | Ventas generadas por clientes recurrentes. | `Revenue Returning Customers = [Sales Total] - [Revenue New Customers]` | Ej.: `...vw_revenue.returning_customers_revenue` | — |
| **Repeat Rate %** | Porcentaje de clientes recurrentes sobre el total de clientes. | `Repeat Rate % = DIVIDE([Returning Customers],[Customers])` | Ej.: `...vw_customers.repeat_rate_pct` | — |

---

## 4) Inteligencia de tiempo

| KPI | Definición de negocio | DAX (medida) | Origen SQL | Nivel / Notas |
|---|---|---|---|---|
| **Sales LM** | Ventas del mes anterior según el contexto actual. | `Sales LM = CALCULATE([Sales Total], DATEADD('Dim Date'[date],-1,MONTH))` | Ej.: `...vw_time.sales_lm` | Requiere una tabla calendario completa. |
| **Sales LY** | Ventas del año anterior según el contexto actual. | `Sales LY = CALCULATE([Sales Total], DATEADD('Dim Date'[date],-1,YEAR))` | Ej.: `...vw_time.sales_ly` | — |
| **Sales MoM %** | Variación porcentual mes contra mes. | `Sales MoM % = DIVIDE([Sales Total]-[Sales LM],[Sales LM])` | Ej.: `...vw_time.sales_mom_pct` | Se recomienda usar la versión segura indicada abajo. |
| **Sales YoY %** | Variación porcentual año contra año. | `Sales YoY % = DIVIDE([Sales Total]-[Sales LY],[Sales LY])` | Ej.: `...vw_time.sales_yoy_pct` | Se recomienda usar la versión segura indicada abajo. |
| **Safe % vs LM** | Variación MoM robusta. Devuelve 0 si el denominador es 0. | `Safe % vs LM = DIVIDE([Sales Total]-[Sales LM],[Sales LM],0)` | — | Recomendada para tarjetas e indicadores ejecutivos. |
| **Safe % vs LY** | Variación YoY robusta. Devuelve 0 si el denominador es 0. | `Safe % vs LY = DIVIDE([Sales Total]-[Sales LY],[Sales LY],0)` | — | — |
| **Sales YTD** | Ventas acumuladas desde el inicio del año hasta la fecha filtrada. | `Sales YTD = TOTALYTD([Sales Total],'Dim Date'[date])` | Ej.: `...vw_time.sales_ytd` | La tabla de fechas debe estar marcada como tabla calendario en Power BI. |

---

## 5) Envíos y operación

| KPI | Definición de negocio | DAX (medida) | Origen SQL | Nivel / Notas |
|---|---|---|---|---|
| **Shipping Cost Total** | Costo total de envío. | `Shipping Cost Total = SUM('Fact Sales'[shipping_cost])` | Ej.: `...vw_shipping.shipping_cost_total` | — |
| **Shipping % Sales** | Costo de envío como porcentaje de las ventas. | `Shipping % Sales = DIVIDE([Shipping Cost Total],[Sales Total])` | Ej.: `...vw_shipping.shipping_pct_sales` | Se utiliza como indicador de carga logística. |
| **Shipping Cost per Order** | Costo promedio de envío por orden. | `Shipping Cost per Order = DIVIDE([Shipping Cost Total],[Orders])` | Ej.: `...vw_shipping.shipping_cost_per_order` | Útil para comparar eficiencia entre modos de envío. |
| **Lead Time (days)** | Promedio de días entre la fecha de orden y la fecha de envío. | <code>Lead Time (days) = AVERAGEX('Fact Sales', DATEDIFF('Fact Sales'[order_date],'Fact Sales'[ship_date],DAY))</code> | Ej.: `...vw_shipping.lead_time_days` | Objetivo de SLA: menor o igual a 4 días. |
| **Sales by Ship Date** | Ventas analizadas según fecha de envío en lugar de fecha de orden. | <code>Sales by Ship Date = CALCULATE([Sales Total], USERELATIONSHIP('Fact Sales'[ship_date],'Dim Date'[date]))</code> | Ej.: `...vw_shipping.sales_by_ship_date` | Permite construir el análisis de órdenes vs. despachos. |

---

## 6) Concentración

| KPI | Definición de negocio | DAX (medida) | Origen SQL | Nivel / Notas |
|---|---|---|---|---|
| **Top 10 Customers %** | Participación de ventas generada por los 10 principales clientes. | `TOPN + DIVIDE([Top Sales],[Sales Total])` | Ej.: `...vw_concentration.top10_cust_pct` | Permite evaluar dependencia de pocos clientes. |
| **Top 10 Products %** | Participación de ventas generada por los 10 principales productos. | `TOPN + DIVIDE([Top Sales],[Sales Total])` | Ej.: `...vw_concentration.top10_prod_pct` | Permite evaluar dependencia de pocos productos. |

---

## Gobierno y criterios de nombres

Para mantener consistencia entre SQL, Power BI y documentación:

- Usar nombres claros y consistentes para las medidas.
- Agrupar medidas por tema cuando sea necesario, por ejemplo: `TIME`, `SHIPPING`, `CUSTOMERS`, `FINANCE`.
- Documentar supuestos importantes, por ejemplo: si las ventas están netas de descuento.
- Usar las vistas publicadas en `global_superstore_bi` como capa estable de consumo para Power BI.
- Evitar que el dashboard dependa directamente de tablas internas de ETL o modelado.
- Mantener este diccionario actualizado cada vez que se cree, modifique o elimine un KPI.

---

## 👩‍💻 Autora

Documento realizado por **Daiana Beltrán**  
[LinkedIn](https://www.linkedin.com/in/daiana-beltran/) · [GitHub](https://github.com/daiana-analytics)
```
