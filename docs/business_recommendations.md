# Business Recommendation Framework

Numerical findings should be written after the BigQuery queries are run and outputs are inspected. Use this framework to translate evidence into actions.

## 1. Funnel diagnosis

Find the stage with the largest absolute and relative drop. Validate event instrumentation before calling it a UX problem. Consider product-page clarity, cart friction, and checkout usability as hypotheses, then test improvements.

## 2. Acquisition quality

Compare users, purchasers, and reported revenue by first-user source/medium. Do not call a source "most efficient" without cost data. Request campaign cost/click data before budget-allocation claims.

## 3. Device experience

Compare session purchase rate and funnel progression by device. Investigate high-volume devices with weaker progression, then validate tagging and usability hypotheses.

## 4. Product merchandising

Compare item views, units sold, cart activity, and item-level revenue. Keep item and event grains separate to avoid duplicated revenue.

## 5. Retention

Review cohort return activity only within the observed window. Define a longer measurement period and use a holdout when testing lifecycle messaging.

## Reporting standard

Every recommendation should include the KPI definition, result and denominator, data-quality caveat, action hypothesis, and measurement plan.
