-- First-user acquisition summary. traffic_source is not per-session attribution.
WITH events AS (
  SELECT event_timestamp, event_name, user_pseudo_id,
    (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id' LIMIT 1) AS ga_session_id,
    COALESCE(NULLIF(traffic_source.source, ''), '(not set)') AS source,
    COALESCE(NULLIF(traffic_source.medium, ''), '(not set)') AS medium,
    COALESCE(NULLIF(traffic_source.name, ''), '(not set)') AS campaign,
    ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),
users AS (
  SELECT user_pseudo_id,
    ARRAY_AGG(STRUCT(source, medium, campaign) ORDER BY event_timestamp LIMIT 1)[OFFSET(0)] AS first_user_acquisition,
    COUNT(DISTINCT IF(ga_session_id IS NOT NULL, CONCAT(user_pseudo_id, '.', CAST(ga_session_id AS STRING)), NULL)) AS observed_sessions,
    COUNTIF(event_name = 'purchase') AS purchase_events,
    ROUND(SUM(IF(event_name = 'purchase', COALESCE(purchase_revenue_usd, 0), 0)), 2) AS purchase_revenue_usd,
    MAX(IF(event_name = 'purchase', 1, 0)) AS purchaser_flag
  FROM events WHERE user_pseudo_id IS NOT NULL GROUP BY user_pseudo_id
)
SELECT first_user_acquisition.source, first_user_acquisition.medium, first_user_acquisition.campaign,
  COUNT(*) AS users, SUM(observed_sessions) AS observed_sessions,
  SUM(purchaser_flag) AS purchaser_users, SUM(purchase_events) AS purchase_events,
  ROUND(SUM(purchase_revenue_usd), 2) AS purchase_revenue_usd,
  ROUND(100*SAFE_DIVIDE(SUM(purchaser_flag), COUNT(*)), 2) AS user_purchase_rate_pct
FROM users
GROUP BY source, medium, campaign
ORDER BY purchase_revenue_usd DESC;