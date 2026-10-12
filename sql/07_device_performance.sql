-- Device comparison by device category.
WITH events AS (
 SELECT COALESCE(NULLIF(device.category,''),'(not set)') AS device_category,event_name,user_pseudo_id,
 (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key='ga_session_id' LIMIT 1) AS ga_session_id,
 ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
 FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT device_category,COUNT(DISTINCT user_pseudo_id) AS users,
 COUNT(DISTINCT IF(user_pseudo_id IS NOT NULL AND ga_session_id IS NOT NULL,CONCAT(user_pseudo_id,'.',CAST(ga_session_id AS STRING)),NULL)) AS sessions,
 COUNT(DISTINCT IF(event_name='purchase',user_pseudo_id,NULL)) AS purchaser_users,COUNTIF(event_name='purchase') AS purchase_events,
 ROUND(SUM(IF(event_name='purchase',COALESCE(purchase_revenue_usd,0),0)),2) AS purchase_revenue_usd,
 ROUND(100*SAFE_DIVIDE(COUNT(DISTINCT IF(event_name='purchase' AND user_pseudo_id IS NOT NULL AND ga_session_id IS NOT NULL,CONCAT(user_pseudo_id,'.',CAST(ga_session_id AS STRING)),NULL)),
 COUNT(DISTINCT IF(user_pseudo_id IS NOT NULL AND ga_session_id IS NOT NULL,CONCAT(user_pseudo_id,'.',CAST(ga_session_id AS STRING)),NULL))),2) AS session_purchase_rate_pct
FROM events GROUP BY device_category ORDER BY sessions DESC;