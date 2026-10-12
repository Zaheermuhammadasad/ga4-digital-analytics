# Interactive Dashboard

The populated dashboard is generated from exported BigQuery query results.

1. Run the SQL files under `../sql/` and export results using `../docs/getting_started.md`.
2. Put the CSV exports into `../outputs/bigquery_exports/`.
3. Run `python ../python/build_dashboard.py`.
4. Open `ga4_digital_analytics_dashboard.html` in a browser.

The builder validates seven required exports and fails with a clear message if any are missing. The checked-in `dashboard_preview.svg` is a design preview, not measured results.