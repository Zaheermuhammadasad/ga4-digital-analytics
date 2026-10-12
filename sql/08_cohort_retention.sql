-- Observed activity retention by first observed month in the selected sample window.
WITH user_months AS (
 SELECT DISTINCT user_pseudo_id,DATE_TRUNC(PARSE_DATE('%Y%m%d',event_date),MONTH) AS activity_month
 FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
 WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131' AND user_pseudo_id IS NOT NULL
), cohorts AS (
 SELECT user_pseudo_id,MIN(activity_month) AS cohort_month FROM user_months GROUP BY user_pseudo_id
), activity AS (
 SELECT c.cohort_month,a.activity_month,DATE_DIFF(a.activity_month,c.cohort_month,MONTH) AS months_since_cohort,
 COUNT(DISTINCT a.user_pseudo_id) AS active_users FROM cohorts c JOIN user_months a USING(user_pseudo_id)
 GROUP BY c.cohort_month,a.activity_month,months_since_cohort
), sizes AS (
 SELECT cohort_month,COUNT(DISTINCT user_pseudo_id) AS cohort_users FROM cohorts GROUP BY cohort_month
)
SELECT a.cohort_month,a.activity_month,a.months_since_cohort,s.cohort_users,a.active_users,
 ROUND(100*SAFE_DIVIDE(a.active_users,s.cohort_users),2) AS retention_pct
FROM activity a JOIN sizes s USING(cohort_month) ORDER BY cohort_month,months_since_cohort;