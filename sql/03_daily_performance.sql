-- Daily activity metrics.
WITH events AS (
 SELECT PARSE_DATE('%Y%m%d',event_date) AS event_dt,event_name,user_pseudo_id,
 (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key='ga_session_id' LIMIT 1) AS ga_session_id,
 ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
 FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
 WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT event_dt AS event_date,COUNT(*) AS event_count,COUNT(DISTINCT user_pseudo_id) AS active_users,
 COUNT(DISTINCT IF(user_pseudo_id IS NOT NULL AND ga_session_id IS NOT NULL,CONCAT(user_pseudo_id,'.',CAST(ga_session_id AS STRING)),NULL)) AS sessions_observed,
 COUNTIF(event_name='page_view') AS page_view_events,COUNTIF(event_name='view_item') AS view_item_events,
 COUNTIF(event_name='add_to_cart') AS add_to_cart_events,COUNTIF(event_name='begin_checkout') AS begin_checkout_events,
 COUNTIF(event_name='purchase') AS purchase_events,COUNT(DISTINCT IF(event_name='purchase',user_pseudo_id,NULL)) AS purchaser_users,
 ROUND(SUM(IF(event_name='purchase',COALESCE(purchase_revenue_usd,0),0)),2) AS purchase_revenue_usd
FROM events GROUP BY event_date ORDER BY event_date;