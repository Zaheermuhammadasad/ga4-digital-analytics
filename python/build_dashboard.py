#!/usr/bin/env python3
"""Build a Plotly dashboard from exported BigQuery query results."""
import argparse
from pathlib import Path
import sys
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.express as px
import plotly.io as pio

REQUIRED = {
    "profile.csv": ["event_count", "user_count", "session_count", "purchase_events", "purchaser_users", "purchase_revenue_usd", "first_event_date", "last_event_date"],
    "daily_performance.csv": ["event_date", "active_users", "sessions_observed", "purchase_events", "purchase_revenue_usd"],
    "funnel.csv": ["step_order", "step_name", "sessions", "progression_rate_pct"],
    "acquisition.csv": ["source", "medium", "campaign", "users", "purchaser_users", "purchase_revenue_usd"],
    "product_performance.csv": ["item_name", "item_category", "units_sold", "item_revenue_usd"],
    "device_performance.csv": ["device_category", "users", "sessions", "purchaser_users", "purchase_revenue_usd"],
    "cohort_retention.csv": ["cohort_month", "months_since_cohort", "cohort_users", "active_users", "retention_pct"],
}

def parse_args():
    root = Path(__file__).resolve().parents[1]
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--exports-dir", default=str(root / "outputs" / "bigquery_exports"))
    p.add_argument("--output", default=str(root / "dashboard" / "ga4_digital_analytics_dashboard.html"))
    return p.parse_args()

def load_exports(folder):
    missing = [name for name in REQUIRED if not (folder / name).exists()]
    if missing:
        raise FileNotFoundError(
            "Missing BigQuery exports: " + ", ".join(missing) +
            ". Run the SQL files and export each result using docs/getting_started.md."
        )
    result = {}
    for name, required_columns in REQUIRED.items():
        df = pd.read_csv(folder / name)
        missing_columns = [c for c in required_columns if c not in df.columns]
        if missing_columns:
            raise ValueError(f"{name} missing required columns: {', '.join(missing_columns)}")
        result[name] = df
    return result

def as_num(value, decimals=0):
    if pd.isna(value):
        return "—"
    return f"{float(value):,.{decimals}f}"

def plot_html(fig):
    return pio.to_html(fig, full_html=False, include_plotlyjs=False, config={"responsive": True, "displaylogo": False})

def main():
    args = parse_args()
    exports_dir = Path(args.exports_dir)
    output = Path(args.output)
    d = load_exports(exports_dir)

    profile = d["profile.csv"].iloc[0]
    daily = d["daily_performance.csv"].copy()
    daily["event_date"] = pd.to_datetime(daily["event_date"], errors="coerce")
    daily = daily.dropna(subset=["event_date"]).sort_values("event_date")
    funnel = d["funnel.csv"].sort_values("step_order").copy()
    acquisition = d["acquisition.csv"].copy()
    products = d["product_performance.csv"].copy()
    devices = d["device_performance.csv"].copy()
    cohort = d["cohort_retention.csv"].copy()
    cohort["cohort_month"] = pd.to_datetime(cohort["cohort_month"], errors="coerce")

    cards = [
        ("Events", as_num(profile["event_count"]), "Rows in event tables"),
        ("Users", as_num(profile["user_count"]), "Pseudonymous user IDs"),
        ("Sessions", as_num(profile["session_count"]), "Complete user/session key"),
        ("Purchaser users", as_num(profile["purchaser_users"]), "Users with purchase event"),
        ("Purchase revenue", "$" + as_num(profile["purchase_revenue_usd"], 2), "GA4 reported revenue; not profit"),
    ]
    card_html = "".join(f'<div class="kpi"><span>{a}</span><strong>{b}</strong><small>{c}</small></div>' for a,b,c in cards)

    f_daily = go.Figure()
    f_daily.add_trace(go.Scatter(x=daily["event_date"], y=daily["active_users"], name="Active users", mode="lines", line={"color":"#4361ee","width":2}))
    f_daily.add_trace(go.Scatter(x=daily["event_date"], y=daily["sessions_observed"], name="Sessions", mode="lines", line={"color":"#2a9d8f","width":2}))
    f_daily.update_layout(title="Daily Active Users & Sessions", template="plotly_white", xaxis_title="Date", yaxis_title="Count", legend_title="")

    f_revenue = px.line(daily, x="event_date", y="purchase_revenue_usd", title="Daily Purchase Revenue", markers=True, template="plotly_white")
    f_revenue.update_layout(xaxis_title="Date", yaxis_title="Reported revenue (USD)")

    funnel["sessions"] = pd.to_numeric(funnel["sessions"], errors="coerce").fillna(0)
    f_funnel = go.Figure(go.Bar(x=funnel["step_name"], y=funnel["sessions"], marker_color=["#4361ee","#4c78a8","#2a9d8f","#f4a261"],
        customdata=funnel["progression_rate_pct"], text=funnel["sessions"].map(as_num), textposition="auto",
        hovertemplate="%{x}<br>Sessions: %{y:,.0f}<br>Progression: %{customdata:.2f}%<extra></extra>"))
    f_funnel.update_layout(title="Sequential Session Funnel", template="plotly_white", xaxis_title="Funnel stage", yaxis_title="Sessions")

    for c in ["users","purchaser_users","purchase_revenue_usd"]:
        acquisition[c] = pd.to_numeric(acquisition[c], errors="coerce").fillna(0)
    acquisition["source_medium"] = acquisition["source"].fillna("(not set)").astype(str) + " / " + acquisition["medium"].fillna("(not set)").astype(str)
    top_acq = acquisition.sort_values("purchase_revenue_usd", ascending=False).head(12).sort_values("purchase_revenue_usd")
    f_acq = go.Figure(go.Bar(x=top_acq["purchase_revenue_usd"],y=top_acq["source_medium"],orientation="h",marker_color="#577590",
        customdata=top_acq[["users","purchaser_users"]],
        hovertemplate="%{y}<br>Revenue: $%{x:,.2f}<br>Users: %{customdata[0]:,.0f}<br>Purchasers: %{customdata[1]:,.0f}<extra></extra>"))
    f_acq.update_layout(title="First-user Acquisition Groups by Revenue",template="plotly_white",xaxis_title="Reported revenue (USD)",yaxis_title="Source / medium")

    products["item_revenue_usd"] = pd.to_numeric(products["item_revenue_usd"],errors="coerce").fillna(0)
    products["units_sold"] = pd.to_numeric(products["units_sold"],errors="coerce").fillna(0)
    top_products = products.sort_values("item_revenue_usd",ascending=False).head(12).sort_values("item_revenue_usd")
    f_products = go.Figure(go.Bar(x=top_products["item_revenue_usd"],y=top_products["item_name"].fillna("(not set)"),orientation="h",marker_color="#2a9d8f",
        customdata=top_products[["units_sold","item_category"]],
        hovertemplate="%{y}<br>Item revenue: $%{x:,.2f}<br>Units: %{customdata[0]:,.0f}<br>Category: %{customdata[1]}<extra></extra>"))
    f_products.update_layout(title="Top Products by Item-level Revenue",template="plotly_white",xaxis_title="Item revenue (USD)",yaxis_title="Product")

    devices["sessions"] = pd.to_numeric(devices["sessions"],errors="coerce").fillna(0)
    devices["purchaser_users"] = pd.to_numeric(devices["purchaser_users"],errors="coerce").fillna(0)
    f_device = make_subplots(specs=[[{"secondary_y":True}]])
    f_device.add_trace(go.Bar(x=devices["device_category"],y=devices["sessions"],name="Sessions",marker_color="#a8b8d8"),secondary_y=False)
    f_device.add_trace(go.Scatter(x=devices["device_category"],y=devices["purchaser_users"],name="Purchaser users",mode="lines+markers",line={"color":"#f4a261","width":3}),secondary_y=True)
    f_device.update_layout(title="Device Category: Sessions & Purchaser Users",template="plotly_white",xaxis_title="Device")
    f_device.update_yaxes(title_text="Sessions",secondary_y=False)
    f_device.update_yaxes(title_text="Purchaser users",secondary_y=True)

    cohort["months_since_cohort"] = pd.to_numeric(cohort["months_since_cohort"],errors="coerce")
    cohort["retention_pct"] = pd.to_numeric(cohort["retention_pct"],errors="coerce")
    heat = cohort.pivot_table(index="cohort_month",columns="months_since_cohort",values="retention_pct",aggfunc="mean")
    heat.index = [v.strftime("%Y-%m") if not pd.isna(v) else "(unknown)" for v in heat.index]
    f_cohort = go.Figure(go.Heatmap(z=heat.values,x=[str(int(v)) for v in heat.columns],y=heat.index,colorscale="Blues",colorbar={"title":"Retention %"},
        hovertemplate="Cohort %{y}<br>Months since cohort: %{x}<br>Retention: %{z:.2f}%<extra></extra>"))
    f_cohort.update_layout(title="Observed Monthly Cohort Retention",template="plotly_white",xaxis_title="Months since first observed month",yaxis_title="Cohort")

    charts = [("Daily activity",f_daily),("Revenue trend",f_revenue),("Conversion funnel",f_funnel),
              ("Acquisition performance",f_acq),("Product performance",f_products),("Device comparison",f_device),("Cohort retention",f_cohort)]
    chart_html = "".join(f'<section class="panel"><div class="panel-title">{title}</div>{plot_html(fig)}</section>' for title,fig in charts)
    first_date = pd.to_datetime(profile["first_event_date"],errors="coerce")
    last_date = pd.to_datetime(profile["last_event_date"],errors="coerce")
    period = f"{first_date:%Y-%m-%d} to {last_date:%Y-%m-%d}" if pd.notna(first_date) and pd.notna(last_date) else "See profile query"
    html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>GA4 Digital Analytics Dashboard</title>
<script src="https://cdn.plot.ly/plotly-2.35.2.min.js"></script><style>
*{{box-sizing:border-box}}body{{margin:0;background:#f4f7fb;color:#182338;font-family:Arial,sans-serif}}main{{max-width:1440px;margin:auto;padding:28px}}h1{{font-size:30px;margin:0 0 6px}}.sub{{color:#667085;margin-bottom:22px;line-height:1.5}}.kpis{{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:12px}}.kpi,.panel,.caveat{{background:white;border:1px solid #e3e9f2;border-radius:14px;box-shadow:0 2px 10px #15294b08}}.kpi{{padding:17px;min-width:0}}.kpi span{{font-size:12px;color:#667085;display:block}}.kpi strong{{font-size:clamp(20px,2.1vw,27px);display:block;margin-top:9px;overflow-wrap:anywhere}}.kpi small{{font-size:11px;color:#8792a5;display:block;margin-top:8px}}.charts{{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px;margin-top:16px}}.panel{{padding:12px;min-width:0;overflow:hidden}}.panel-title{{font-size:13px;font-weight:700;color:#667085;margin:5px 8px 0}}.caveat{{padding:18px;margin-top:16px;font-size:12px;color:#5f6e83;line-height:1.6}}.footer{{font-size:11px;color:#8792a5;margin-top:16px}}@media(max-width:1000px){{.kpis{{grid-template-columns:repeat(2,minmax(0,1fr))}}.charts{{grid-template-columns:1fr}}main{{padding:15px}}}}
</style></head><body><main><h1>GA4 Digital Analytics</h1><div class="sub">Acquisition · Session funnel · Product performance · Device behaviour · Cohort retention<br>Observed sample range: {period}</div>
<section class="kpis">{card_html}</section><section class="charts">{chart_html}</section>
<section class="caveat"><b>Interpretation boundaries:</b> The sample is obfuscated and may have internal inconsistencies. First-user source is not session attribution; user IDs are pseudonymous; item revenue is not profit. No dependable campaign-cost or randomized holdout data are supplied, so ROAS, CAC and causal lift are not estimated.</section>
<div class="footer">Built from exported BigQuery query results. Check query date filters and metric definitions before comparing results.</div></main></body></html>'''
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(html,encoding="utf-8")
    print(f"Dashboard generated: {output}")
    print(f"Input exports validated: {len(REQUIRED)} files.")

if __name__ == "__main__":
    try:
        main()
    except (FileNotFoundError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(2)
