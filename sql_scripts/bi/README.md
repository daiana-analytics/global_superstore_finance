# 📊 BI Scripts

Views for dashboards and the published contract layer in `global_superstore_bi`.

## Contents
- **04_views_dashboard.sql** → Base financial & dashboard views
- **10_dashboard_views.sql** → Thematic views (executive, time, product, geo, customer, logistics)
- **12_bi_role_user.sql** → Create parameterized BI role & user (idempotent)
- **13_bi_schema_and_grants.sql** → Create curated BI schema and grant SELECT to role
- **14_publish_bi_views.sql** → Publish contract views (`vw_*`) into `global_superstore_bi`
- **15_verification_tests.sql** → Automated validation (SELECT-only; denies INSERT/UPDATE/DELETE/CREATE/DROP)

## Security
Published BI layer is accessible only via role **`bi_reader_role`** / user **`bi_reader@%`** (principle of least privilege).
