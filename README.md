# 📊 Global Superstore Finance — Proyecto de Análisis Financiero con SQL y Power BI

**ETL → Modelo en estrella → KPIs financieros → Dashboard en Power BI**  
Proyecto de portafolio que simula un flujo completo de análisis financiero, desde la limpieza y transformación de datos hasta la construcción de indicadores y visualizaciones para la toma de decisiones.

<p align="center">
  <a href="dashboards/powerbi/templates/GlobalSuperstore_Finance_Dashboard.pbit"><b>⬇️ Descargar plantilla PBIT</b></a> ·
  <a href="#dashboard-pages"><b>📺 Ver páginas del dashboard</b></a> ·
  <a href="./docs/README.md"><b>📘 README detallado</b></a>
</p>



<div align="center">
  <img src="dashboards/powerbi/assets/powerbi-dashboard-demo.gif"
       alt="Demo del dashboard financiero Global Superstore en Power BI"
       width="900"/>
</div>

---

## 🔎 Preguntas de negocio respondidas

Este proyecto busca responder preguntas clave para analizar el rendimiento financiero y operativo de una empresa:

- ¿De dónde provienen los ingresos: clientes nuevos o clientes recurrentes?
- ¿Qué segmentos y categorías generan más ventas y mejor margen?
- ¿Las ventas están creciendo mes a mes y año a año?
- ¿Qué meses y trimestres concentran mayor demanda?
- ¿Qué método de envío vende más y cuál genera mayor carga logística?
- ¿La empresa cumple con el objetivo de entrega de hasta 4 días?
- ¿Existe acumulación de pedidos pendientes entre órdenes y despachos?

---

## 🚀 Estructura del repositorio

- 📂 **[sql_scripts/](./sql_scripts/)** → Scripts SQL organizados por ETL, modelado, capa BI y administración.  
- 📂 **[docs/](./docs/)** → Documentación, diagramas y decisiones de diseño.  
- 📂 **[dashboards/](./dashboards/)** → Archivos de Power BI, capturas del dashboard y recursos visuales.  

---

## 📑 Índice de carpetas

- 🔹 **ETL** → [Ver scripts](./sql_scripts/etl)  
- 🔹 **Modelado** → [Ver scripts](./sql_scripts/modeling)  
- 🔹 **BI** → [Ver scripts](./sql_scripts/bi)  
- 🔹 **Admin** → [Ver scripts](./sql_scripts/admin)  
- 🔹 **Docs** → [Ver documentación](./docs)  
- 🔹 **Dashboards** → [Ver dashboards](./dashboards)  

---

## 🎯 Objetivo del proyecto

El objetivo de este repositorio es demostrar un flujo completo de **Financial Analytics** aplicado a un caso de negocio.

El proyecto incluye:

1. **ETL** → Carga, limpieza y transformación de datos desde capas iniciales hasta datos listos para análisis.  
2. **Modelado** → Construcción de un modelo en estrella con tablas de hechos y dimensiones.  
3. **KPIs** → Creación de indicadores financieros y operativos relevantes para el negocio.  
4. **BI** → Vistas preparadas para consumo desde Power BI.  
5. **Gobernanza** → Separación entre datos crudos, datos limpios y vistas finales para análisis.  
6. **Dashboard** → Visualización final en Power BI con foco en storytelling y toma de decisiones.  

---

<a id="dashboard-pages"></a>
## 🖥️ Power BI — Páginas e insights

### 01 — Financial Overview

*Vista general de ingresos, clientes, segmentos, categorías, margen y descuentos.*

<div>
  <img src="dashboards/powerbi/assets/01-financial-overview.png"
       alt="Página 1 – Financial Overview: KPIs, revenue mix, margen por segmento y descuentos"
       width="900"/>
</div>

**Principales insights**

- **Mix de ingresos:** aproximadamente el **70% de los ingresos** proviene de **clientes recurrentes**, lo que muestra una base de clientes estable.
- **Segmentos:** el segmento **Consumer** lidera en ventas, mientras que **Home Office** muestra el mejor margen.
- **Categorías:** **Technology** presenta alto nivel de ventas y mejor rentabilidad relativa. **Furniture** vende en niveles similares, pero con menor margen.
- **Descuentos y margen:** la categoría **Tables** aparece como un punto crítico: combina descuentos altos con margen negativo, por lo que requiere revisión comercial.

---

### 02 — Time & Seasonality

*Análisis de evolución temporal, crecimiento mensual/anual y estacionalidad.*

<div>
  <img src="dashboards/powerbi/assets/02-time-and-seasonality.png"
       alt="Página 2 – Time & Seasonality: evolución mensual, crecimiento anual y estacionalidad"
       width="900"/>
</div>

**Principales insights**

- Se observa **crecimiento interanual sostenido**, con mayor aceleración en los últimos meses del año.
- **Q4** es el trimestre más fuerte en ventas, lo que indica una concentración importante de demanda hacia fin de año.
- **Diciembre** aparece como el mes pico de ventas de forma consistente.
- Este patrón permite anticipar períodos de mayor demanda y planificar inventario, logística y campañas comerciales.

---

### 03 — Shipping & Operations

*Análisis operativo de tiempos de entrega, modos de envío, costos logísticos y backlog.*

<div>
  <img src="dashboards/powerbi/assets/03-shipping-operations.png"
       alt="Página 3 – Shipping & Operations: lead time, modos de envío, ventas y backlog"
       width="900"/>
</div>

**Principales insights**

- **SLA de entrega:** Same Day, First Class y Second Class cumplen con el objetivo de entrega de hasta 4 días.  
- **Standard Class** supera el objetivo, con un tiempo promedio de entrega de 5 días, por lo que queda fuera del SLA.
- **Eficiencia logística:** Standard Class concentra el mayor volumen de ventas y tiene menor carga de envío relativa.
- **Same Day** es el método más costoso, por lo que debe usarse estratégicamente.
- **Órdenes vs. despachos:** hacia fin de año se observa mayor volumen de despachos, lo que puede indicar limpieza de backlog acumulado.

---

## 📌 DAX Highlights · [Diccionario de KPIs](./docs/kpi_dictionary.md)

El dashboard incluye medidas DAX orientadas a análisis financiero y seguimiento temporal:

- **Time intelligence:** medidas para analizar evolución YTD, MoM y YoY.
- **Comparaciones seguras:** cálculos preparados para evitar errores ante filtros o meses sin datos.
- **KPIs financieros:** ventas, profit, margen, descuentos y variaciones.
- **Usabilidad:** etiquetas, tooltips y visualizaciones pensadas para facilitar la lectura ejecutiva del dashboard.

---

## 🔐 Gobernanza

El proyecto incorpora buenas prácticas básicas de organización y consumo de datos:

- Separación entre capas de datos: crudo, limpio, calidad y BI.
- Vistas finales preparadas para ser consumidas desde Power BI.
- Rol de solo lectura para usuarios de BI.
- Estructura pensada para que el dashboard consuma datos consistentes y controlados.

---

## 🧪 Cómo ejecutar el proyecto

### 1) SQL

- Crear la base de datos.
- Ejecutar los scripts ubicados en **`sql_scripts`** siguiendo este orden:

```text
etl/ → modeling/ → bi/ → admin/
```

- La capa final de BI queda disponible para ser utilizada desde Power BI.

### 2) Power BI

- Abrir la plantilla:

```text
dashboards/powerbi/templates/GlobalSuperstore_Finance_Dashboard.pbit
```

- Conectar el modelo a las vistas finales de BI.
- Actualizar el modelo y explorar las páginas del dashboard.

> Para una explicación paso a paso, ver el **[README detallado](./docs/README.md)**.

---

## 📌 Dataset

- **Fuente:** [Global Superstore Dataset](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)  
- **Uso:** Dataset público utilizado con fines educativos y de práctica en análisis de datos.

---

## 🛠️ Tecnologías utilizadas

- **SQL** para carga, limpieza, transformación y modelado de datos.  
- **Power BI** para visualización, modelado semántico y creación de KPIs.  
- **DAX** para medidas financieras, temporales y comparativas.  
- **GitHub** para documentación y control de versiones.

---

## 💡 Valor del proyecto

Este proyecto demuestra mi capacidad para trabajar un caso de análisis de datos de punta a punta:

- Entender preguntas de negocio.
- Preparar y transformar datos.
- Diseñar un modelo orientado a análisis.
- Construir KPIs relevantes.
- Crear dashboards claros en Power BI.
- Comunicar insights financieros y operativos de forma visual y accionable.

---

## 👩‍💻 Autora
Proyecto realizado por **Daiana Beltrán**  
[LinkedIn](https://www.linkedin.com/in/daiana-beltran/) · [GitHub](https://github.com/daiana-analytics)
