# Limitations and Interpretation Rules

1. **Obfuscation:** Google notes the sample is obfuscated and may have limited internal consistency.
2. **Historical window:** Three months of sample activity do not reveal longer-term retention.
3. **Identity:** `user_pseudo_id` is pseudonymous and does not guarantee person-level identity.
4. **Attribution:** Top-level `traffic_source` is first-user acquisition, not per-session source/medium attribution.
5. **Revenue:** Revenue fields can be missing or inconsistent; item and purchase-event metrics have different grains. Revenue is not profit.
6. **No media cost:** There is no dependable ad-cost, impression or click table for ROAS, CAC or paid-media ROI.
7. **No experiment:** There is no randomized holdout for incremental or causal claims.
8. **Event logging:** Funnel results depend on instrumentation and session boundaries.
9. **Coverage:** Exact counts depend on the `_TABLE_SUFFIX` range. Keep the query date range with any reported results.
