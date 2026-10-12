# Data Model

The GA4 BigQuery export is event-level, with nested and repeated fields.

## Key fields

- `event_date`: date as `YYYYMMDD`.
- `event_timestamp`: event timestamp in microseconds.
- `event_name`: event type, such as `page_view`, `view_item`, `add_to_cart`, `begin_checkout`, and `purchase`.
- `user_pseudo_id`: pseudonymous user/browser identifier.
- `event_params`: repeated key/value pairs; `ga_session_id` is extracted from this array.
- `traffic_source.source`, `.medium`, `.name`: first-user acquisition fields.
- `device.category`: device category.
- `ecommerce.purchase_revenue_in_usd`, `ecommerce.transaction_id`: purchase event details.
- `items`: repeated product rows containing IDs, names/categories, quantities and prices/revenue.

## Derived reporting grains

| Derived table | Grain | Purpose |
|---|---|---|
| Daily performance | Event date | Trend reporting |
| Session funnel | User/session pair | Sequential journey analysis |
| Acquisition | First-user source/medium/campaign | Acquisition cohort comparison |
| Product performance | Item/product group | Items, units and item-level revenue |
| Device performance | Device category | Device comparison |
| Cohort retention | Cohort month and activity-month offset | Observed return activity |

**Important:** Avoid combining item-level `UNNEST(items)` with summing event-level purchase revenue. One purchase event can have multiple item rows and inflate totals if the grain is not controlled.
