# 🛠️ ETL Scripts

Data ingestion, normalization and cleansing pipeline (CSV → STAGE → RAW → CLEAN).

## Contents
- **00_create_database.sql** — Create schema `global_superstore_finance`.
- **01_create_stage_table.sql** — STAGE table (CSV import as-is).
- **02d_build_stage_norm.sql** — Normalize numeric strings stored as text.
- **02d_fix_hyphen_decimal.sql** — Fix hyphen-as-decimal anomalies.
- **02e_load_raw_from_stage_norm.sql** — Load RAW tables with controlled casts.
- **03_load_clean_from_raw.sql** — Build CLEAN layer (derived fields, KPIs base, flags).
- **05_data_quality_audit.sql** — Data Quality framework (`etl_runs`, `dq_metrics`, `dq_issues`).

## Suggested Run Order
`00 → 01 → 02d_build → 02d_fix → 02e → 03 → 05`

> Outcome: trusted **CLEAN** layer ready for modeling and BI.
