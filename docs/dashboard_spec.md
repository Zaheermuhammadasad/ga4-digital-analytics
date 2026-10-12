# Dashboard Specification

The generated interactive dashboard includes:

1. **Executive KPIs:** event count, pseudonymous users, sessions, purchaser users and reported purchase revenue.
2. **Daily activity:** active users and observed sessions by date.
3. **Revenue trend:** daily purchase revenue.
4. **Sequential session funnel:** users/sessions advancing through view item, add to cart, begin checkout and purchase.
5. **First-user acquisition:** source/medium groups by reported revenue, users and purchasers.
6. **Products:** top items by item-level revenue and units.
7. **Devices:** sessions and purchaser users by device category.
8. **Cohort retention:** heatmap of observed monthly retention by cohort age.

All numerical values are derived from exported BigQuery query results. The HTML builder refuses to create the final dashboard when required exports or fields are absent.
