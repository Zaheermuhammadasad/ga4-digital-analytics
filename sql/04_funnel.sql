-- Sequential session funnel: view_item -> add_to_cart -> begin_checkout -> purchase.
WITH relevant AS (
 SELECT CONCAT(user_pseudo_id,'.',CAST((SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key='ga_session_id' LIMIT 1) AS STRING)) AS session_key,
 event_name,event_timestamp
 FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
 WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
 AND event_name IN ('view_item','add_to_cart','begin_checkout','purchase') AND user_pseudo_id IS NOT NULL
 AND (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key='ga_session_id' LIMIT 1) IS NOT NULL
), sessions AS (
 SELECT session_key,ARRAY_AGG(STRUCT(event_name,event_timestamp) ORDER BY event_timestamp) AS rows FROM relevant GROUP BY session_key
), s1 AS (
 SELECT session_key,rows,(SELECT MIN(x.event_timestamp) FROM UNNEST(rows) x WHERE x.event_name='view_item') AS view_ts FROM sessions
), s2 AS (
 SELECT *, (SELECT MIN(x.event_timestamp) FROM UNNEST(rows) x WHERE x.event_name='add_to_cart' AND x.event_timestamp>=view_ts) AS cart_ts FROM s1
), s3 AS (
 SELECT *, (SELECT MIN(x.event_timestamp) FROM UNNEST(rows) x WHERE x.event_name='begin_checkout' AND x.event_timestamp>=cart_ts) AS checkout_ts FROM s2
), session_steps AS (
 SELECT session_key,view_ts,cart_ts,checkout_ts,(SELECT MIN(x.event_timestamp) FROM UNNEST(rows) x WHERE x.event_name='purchase' AND x.event_timestamp>=checkout_ts) AS purchase_ts FROM s3
), counts AS (
 SELECT COUNTIF(view_ts IS NOT NULL) AS view_sessions,COUNTIF(cart_ts IS NOT NULL) AS cart_sessions,
 COUNTIF(checkout_ts IS NOT NULL) AS checkout_sessions,COUNTIF(purchase_ts IS NOT NULL) AS purchase_sessions FROM session_steps
)
SELECT 1 AS step_order,'Product view' AS step_name,view_sessions AS sessions,CAST(NULL AS INT64) AS prior_stage_sessions,CAST(NULL AS FLOAT64) AS progression_rate_pct FROM counts
UNION ALL SELECT 2,'Add to cart',cart_sessions,view_sessions,ROUND(100*SAFE_DIVIDE(cart_sessions,view_sessions),2) FROM counts
UNION ALL SELECT 3,'Begin checkout',checkout_sessions,cart_sessions,ROUND(100*SAFE_DIVIDE(checkout_sessions,cart_sessions),2) FROM counts
UNION ALL SELECT 4,'Purchase',purchase_sessions,checkout_sessions,ROUND(100*SAFE_DIVIDE(purchase_sessions,checkout_sessions),2) FROM counts
ORDER BY step_order;