# 📊 BI Scripts

Views for dashboards and published contract layer in `global_superstore_bi`.

## Contents
- **04_views_dashboard.sql** → Financial & dashboard views
- **06_views_fact.sql** → FACT view (valid sales) for BI
- **07_views_dimensions.sql** → DIM views (date, product, geo) for BI
- **10_dashboard_views.sql** → Thematic views (executive, time, product, geo, customer, logistics)
- **14_publish_bi_views.sql** → Publish contract views (`vw_*`) to `global_superstore_bi`
- **15_verification_tests.sql** → Automated BI validation tests

## Security
Published BI layer accessible only via role **`bi_reader_role`** / user **`bi_reader@%`** (principle of least privilege).
