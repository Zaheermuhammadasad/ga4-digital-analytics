# KPI Definitions

| KPI | Definition | Caveat |
|---|---|---|
| Total events | Rows in selected event tables | Event is not a user or session |
| Active users | Distinct non-null `user_pseudo_id` | Pseudonymous ID, not guaranteed person identity |
| Sessions | Distinct user/session ID pairs with both components present | Events missing session ID excluded from session metrics |
| Purchaser users | Distinct user IDs with a purchase event | Depends on event tagging and identity availability |
| Purchase events | Count of rows where `event_name = 'purchase'` | May differ from transaction count |
| Purchase revenue | Sum of `ecommerce.purchase_revenue_in_usd` for purchase events | Obfuscated sample; revenue is not profit |
| Item revenue | Item-level revenue from `items` on purchase events | Do not multiply event-level revenue through item expansion |
| Funnel stage | Distinct sessions passing event stages in timestamp order | Strict session-based sequential definition |
| First-user source | `traffic_source.source` at user level | Not each session's attribution source |
| Monthly retention | Users active in month N divided by observed cohort size | Short period, and first observed month is not necessarily first-ever activity |
