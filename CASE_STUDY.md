# Case Study — GA4 Digital Analytics

## Business context
A digital commerce team needs consistent reporting for acquisition, session behaviour, ecommerce funnel progression, product performance and observed retention.

## Approach
Use BigQuery GoogleSQL against public GA4 event tables, extract `ga_session_id` from repeated `event_params`, build a sequential session funnel, separate first-user acquisition from session-level attribution, and unnest `items` only for item-level analysis. Profile data quality before interpreting performance.

## Deliverables
- Eight BigQuery SQL queries.
- Metric definitions and a data model.
- Data quality and interpretation caveats.
- Python/Pandas dashboard builder and Plotly dashboard.
- A recommendation framework that connects findings with test plans.

## Reproducibility status
This repository contains query and reporting code. Execute the SQL in BigQuery and export the results to create a populated dashboard. No BigQuery execution is claimed as completed from the authoring environment.
