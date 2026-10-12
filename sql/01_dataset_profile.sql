-- GA4 public ecommerce dataset profile.
WITH events AS (
 SELECT SAFE.PARSE_DATE('%Y%m%d',event_date) AS event_dt,event_name,user_pseudo_id,
 (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key='ga_session_id' LIMIT 1) AS ga_session_id,
 ecommerce.purchase_revenue_in_usd AS purchase_revenue_usd
 FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
 WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT COUNT(*) AS event_count,COUNT(DISTINCT user_pseudo_id) AS user_count,
 COUNT(DISTINCT IF(user_pseudo_id IS NOT NULL AND ga_session_id IS NOT NULL,CONCAT(user_pseudo_id,'.',CAST(ga_session_id AS STRING)),NULL)) AS session_count,
 COUNT(DISTINCT event_dt) AS event_days,COUNTIF(event_name='purchase') AS purchase_events,
 COUNT(DISTINCT IF(event_name='purchase',user_pseudo_id,NULL)) AS purchaser_users,
 ROUND(SUM(IF(event_name='purchase',COALESCE(purchase_revenue_usd,0),0)),2) AS purchase_revenue_usd,
 MIN(event_dt) AS first_event_date,MAX(event_dt) AS last_event_date FROM events;