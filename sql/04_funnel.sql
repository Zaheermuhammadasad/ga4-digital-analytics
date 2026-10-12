-- Sequential session funnel: view_item -> add_to_cart -> begin_checkout -> purchase.
-- Each stage timestamp is selected only after the prior stage timestamp.
WITH relevant_events AS (
  SELECT
    CONCAT(user_pseudo_id, '.', CAST(
      (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id' LIMIT 1)
      AS STRING)) AS session_key,
    event_name, event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'begin_checkout', 'purchase')
    AND user_pseudo_id IS NOT NULL
    AND (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id' LIMIT 1) IS NOT NULL
),
session_events AS (
  SELECT session_key, ARRAY_AGG(STRUCT(event_name, event_timestamp) ORDER BY event_timestamp) AS event_rows
  FROM relevant_events GROUP BY session_key
),
stage_1 AS (
  SELECT session_key, event_rows,
    (SELECT MIN(e.event_timestamp) FROM UNNEST(event_rows) e WHERE e.event_name = 'view_item') AS view_item_ts
  FROM session_events
),
stage_2 AS (
  SELECT *,
    (SELECT MIN(e.event_timestamp) FROM UNNEST(event_rows) e
     WHERE e.event_name = 'add_to_cart' AND e.event_timestamp >= view_item_ts) AS add_to_cart_ts
  FROM stage_1
),
stage_3 AS (
  SELECT *,
    (SELECT MIN(e.event_timestamp) FROM UNNEST(event_rows) e
     WHERE e.event_name = 'begin_checkout' AND e.event_timestamp >= add_to_cart_ts) AS begin_checkout_ts
  FROM stage_2
),
session_steps AS (
  SELECT session_key, view_item_ts, add_to_cart_ts, begin_checkout_ts,
    (SELECT MIN(e.event_timestamp) FROM UNNEST(event_rows) e
     WHERE e.event_name = 'purchase' AND e.event_timestamp >= begin_checkout_ts) AS purchase_ts
  FROM stage_3
),
counts AS (
  SELECT COUNTIF(view_item_ts IS NOT NULL) AS view_item_sessions,
         COUNTIF(add_to_cart_ts IS NOT NULL) AS add_to_cart_sessions,
         COUNTIF(begin_checkout_ts IS NOT NULL) AS checkout_sessions,
         COUNTIF(purchase_ts IS NOT NULL) AS purchase_sessions
  FROM session_steps
)
SELECT 1 AS step_order, 'Product view' AS step_name, view_item_sessions AS sessions,
       CAST(NULL AS INT64) AS prior_stage_sessions, CAST(NULL AS FLOAT64) AS progression_rate_pct FROM counts
UNION ALL
SELECT 2, 'Add to cart', add_to_cart_sessions, view_item_sessions,
       ROUND(100*SAFE_DIVIDE(add_to_cart_sessions, view_item_sessions), 2) FROM counts
UNION ALL
SELECT 3, 'Begin checkout', checkout_sessions, add_to_cart_sessions,
       ROUND(100*SAFE_DIVIDE(checkout_sessions, add_to_cart_sessions), 2) FROM counts
UNION ALL
SELECT 4, 'Purchase', purchase_sessions, checkout_sessions,
       ROUND(100*SAFE_DIVIDE(purchase_sessions, checkout_sessions), 2) FROM counts
ORDER BY step_order;