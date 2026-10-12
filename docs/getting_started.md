# Getting Started

## BigQuery access

Use Google's [GA4 ecommerce sample dataset documentation](https://developers.google.com/analytics/bigquery/web-ecommerce-demo-dataset). Dataset ID:

`bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

Google documents coverage from 2020-11-01 through 2021-01-31. Open BigQuery in Google Cloud Console, use the query editor, and review the on-screen processing estimate before running queries.

## Run and export queries

Run each SQL file separately and export the result using the exact name below:

| SQL file | Export filename |
|---|---|
| `01_dataset_profile.sql` | `profile.csv` |
| `02_data_quality.sql` | `data_quality.csv` |
| `03_daily_performance.sql` | `daily_performance.csv` |
| `04_funnel.sql` | `funnel.csv` |
| `05_acquisition.sql` | `acquisition.csv` |
| `06_product_performance.sql` | `product_performance.csv` |
| `07_device_performance.sql` | `device_performance.csv` |
| `08_cohort_retention.sql` | `cohort_retention.csv` |

Save the files in `outputs/bigquery_exports/`.

## Build the dashboard

Use Python 3.10+:

```bash
python -m pip install -r python/requirements.txt
python python/build_dashboard.py
```

The script validates every required export and their columns, then generates `dashboard/ga4_digital_analytics_dashboard.html`. Open the HTML in a browser. Plotly is loaded from a CDN, so internet access is needed for interactive charts.

## Important

If a query export is missing, the builder stops with an actionable error. Do not fill missing query results with made-up numbers.
