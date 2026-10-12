-- Diagnostics for IDs, sessions, and purchase data.
WITH events AS (
  SELECT event_name, user_pseudo_id, event_params,
         ecommerce.transaction_id AS transaction_id,
         ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd,
         SAFE.PARSE_DATE('%Y%m%d', event_date) AS event_dt
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  COUNT(*) AS total_events,
  COUNTIF(user_pseudo_id IS NULL) AS events_missing_user_id,
  COUNTIF(event_name IS NULL OR TRIM(event_name) = '') AS events_missing_event_name,
  COUNTIF(event_dt IS NULL) AS events_invalid_date,
  COUNTIF((SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id' LIMIT 1) IS NULL) AS events_missing_session_id,
  COUNTIF(event_name = 'purchase') AS purchase_events,
  COUNTIF(event_name = 'purchase' AND (transaction_id IS NULL OR TRIM(transaction_id) = '')) AS purchase_missing_transaction_id,
  COUNTIF(event_name = 'purchase' AND purchase_revenue_usd IS NULL) AS purchase_missing_revenue,
  COUNTIF(event_name = 'purchase' AND COALESCE(purchase_revenue_usd, 0) = 0) AS purchase_zero_or_missing_revenue,
  COUNT(DISTINCT IF(event_name = 'purchase' AND transaction_id IS NOT NULL AND TRIM(transaction_id) != '', transaction_id, NULL)) AS distinct_transaction_ids
FROM events;