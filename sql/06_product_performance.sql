-- Item-grain analysis; use item-level revenue rather than event-level revenue after UNNEST.
SELECT item.item_id,item.item_name,COALESCE(NULLIF(item.item_category,''),'(not set)') AS item_category,
 SUM(COALESCE(item.quantity,0)) AS units_sold,COUNT(DISTINCT e.ecommerce.transaction_id) AS distinct_transactions,
 ROUND(SUM(COALESCE(item.item_revenue_in_usd,item.price_in_usd*item.quantity,0)),2) AS item_revenue_usd,COUNT(*) AS purchase_item_rows
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` e
CROSS JOIN UNNEST(e.items) AS item
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131' AND e.event_name='purchase'
GROUP BY item.item_id,item.item_name,item_category ORDER BY item_revenue_usd DESC;