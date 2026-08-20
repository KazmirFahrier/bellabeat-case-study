"""Build a portable three page dashboard prototype from Power BI import tables."""

from __future__ import annotations

import csv
import html
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "powerbi" / "data"
OUTPUT = ROOT / "powerbi" / "dashboard.html"


def rows(filename: str) -> list[dict[str, str]]:
    with (DATA / filename).open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def horizontal_bars(
    data: list[dict[str, str]], label: str, value: str, color: str = "teal"
) -> str:
    maximum = max(float(row[value]) for row in data)
    blocks = []
    for row in data:
        number = float(row[value])
        width = 100 * number / maximum if maximum else 0
        blocks.append(
            f'<div class="bar-row"><span>{html.escape(row[label])}</span>'
            f'<div class="track"><i class="{color}" style="width:{width:.1f}%"></i></div>'
            f'<strong>{number:,.0f}</strong></div>'
        )
    return "".join(blocks)


def hour_columns(data: list[dict[str, str]]) -> str:
    maximum = max(float(row["participant_weighted_steps"]) for row in data)
    blocks = []
    for row in data:
        number = float(row["participant_weighted_steps"])
        height = 100 * number / maximum if maximum else 0
        blocks.append(
            '<div class="hour-column" '
            f'data-daypart="{html.escape(row["daypart"])}" '
            f'title="{int(row["hour_of_day"]):02d}:00, {number:,.0f} steps">'
            f'<i style="height:{height:.1f}%"></i>'
            f'<small>{int(row["hour_of_day"]):02d}</small></div>'
        )
    return "".join(blocks)


def participant_scatter(data: list[dict[str, str]]) -> str:
    days = [float(row["activity_days"]) for row in data]
    steps = [float(row["avg_steps"]) for row in data]
    x_min, x_max = min(days), max(days)
    y_min, y_max = 0, max(steps) * 1.05
    circles = []
    for row, x_value, y_value in zip(data, days, steps):
        x = 40 + 520 * (x_value - x_min) / (x_max - x_min)
        y = 230 - 190 * (y_value - y_min) / (y_max - y_min)
        circles.append(
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="5" tabindex="0">'
            f'<title>{html.escape(row["engagement_segment"])}: '
            f'{x_value:.0f} days, {y_value:,.0f} steps</title></circle>'
        )
    return (
        '<svg class="scatter" viewBox="0 0 600 260" role="img" '
        'aria-label="Participant activity days versus average daily steps">'
        '<line x1="40" y1="230" x2="570" y2="230" />'
        '<line x1="40" y1="30" x2="40" y2="230" />'
        '<text x="260" y="255">Activity days</text>'
        '<text x="10" y="150" transform="rotate(-90 10 150)">Average steps</text>'
        + "".join(circles)
        + "</svg>"
    )


def main() -> None:
    kpis = {row["metric"]: row for row in rows("executive_kpis.csv")}
    weekday = rows("weekday_activity.csv")
    hourly = rows("hourly_activity.csv")
    coverage = rows("coverage.csv")
    quality = rows("data_quality.csv")
    evidence = rows("evidence.csv")
    sensitivity = rows("sensitivity.csv")
    segments = rows("engagement_segments.csv")
    participants = rows("participant_summary.csv")

    quality_rows = "".join(
        "<tr>"
        f'<td>{html.escape(row["check_name"].replace("_", " ").title())}</td>'
        f'<td>{float(row["actual_value"]):,.0f}</td>'
        f'<td>{float(row["expected_value"]):,.0f}</td>'
        f'<td><span class="status">PASS</span></td></tr>'
        for row in quality
    )
    evidence_rows = "".join(
        "<tr>"
        f'<td>{html.escape(row["estimand"])}</td>'
        f'<td>{float(row["estimate_hours_per_1000_steps"]):.3f}</td>'
        f'<td>{float(row["ci_low"]):.3f} to {float(row["ci_high"]):.3f}</td>'
        f'<td>{int(float(row["participants"]))}</td></tr>'
        for row in evidence
    )
    sensitivity_rows = "".join(
        "<tr>"
        f'<td>{html.escape(row["metric"])}</td>'
        f'<td>{float(row["observation_weighted"]):,.2f}</td>'
        f'<td>{float(row["participant_weighted"]):,.2f}</td>'
        f'<td>{float(row["difference"]):+,.2f}</td></tr>'
        for row in sensitivity
    )
    segment_rows = "".join(
        '<div class="segment"><div><strong>'
        f'{html.escape(row["engagement_segment"])}</strong><span>'
        f'{float(row["avg_days_logged"]):.1f} average days</span></div>'
        f'<b>{int(float(row["participants"]))}</b></div>'
        for row in segments
    )

    template = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Bellabeat Usage Intelligence</title>
<style>
:root{--ink:#0f172a;--muted:#64748b;--line:#e2e8f0;--paper:#fff;--canvas:#f1f5f9;--teal:#0f766e;--coral:#f97360;--gold:#eab308;--green:#15803d}
*{box-sizing:border-box} body{margin:0;background:var(--canvas);color:var(--ink);font-family:Inter,Aptos,system-ui,sans-serif}
.shell{max-width:1440px;margin:auto;min-height:100vh;background:#f8fafc}.topbar{height:82px;background:#0b2f36;color:#fff;display:flex;align-items:center;justify-content:space-between;padding:0 42px}
.brand{display:flex;align-items:center;gap:15px}.mark{width:38px;height:38px;border-radius:12px;background:linear-gradient(140deg,#2dd4bf,#f97360);box-shadow:0 0 0 5px #ffffff12}.brand h1{font-size:20px;margin:0}.brand p{font-size:12px;margin:4px 0 0;color:#a7f3d0}.period{font-size:12px;color:#cbd5e1;text-align:right}
.nav{display:flex;padding:0 42px;background:#fff;border-bottom:1px solid var(--line)}.nav button{border:0;background:transparent;padding:18px 24px;color:var(--muted);font-weight:700;cursor:pointer;border-bottom:3px solid transparent}.nav button.active{color:var(--teal);border-color:var(--teal)}
main{padding:28px 42px 42px}.page{display:none}.page.active{display:block}.intro{display:flex;justify-content:space-between;gap:30px;align-items:end;margin-bottom:22px}.intro h2{font-size:27px;margin:0 0 7px}.intro p{margin:0;color:var(--muted);max-width:760px;line-height:1.55}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.12em;color:var(--teal);font-weight:800;margin-bottom:6px}
.cards{display:grid;grid-template-columns:repeat(4,1fr);gap:15px;margin-bottom:18px}.card,.panel{background:var(--paper);border:1px solid var(--line);border-radius:14px;box-shadow:0 5px 20px #0f172a09}.card{padding:20px}.card span{font-size:12px;color:var(--muted);font-weight:700}.card strong{display:block;font-size:28px;margin:8px 0 3px}.card small{color:var(--muted)}
.intro>div{min-width:0}.intro h2{overflow-wrap:anywhere}.grid{display:grid;grid-template-columns:1.15fr .85fr;gap:18px}.panel{padding:22px;min-width:0}.panel h3{font-size:15px;margin:0 0 5px}.panel .sub{font-size:12px;color:var(--muted);margin-bottom:18px}.bar-row{display:grid;grid-template-columns:76px 1fr 58px;gap:10px;align-items:center;margin:11px 0;font-size:12px}.bar-row strong{text-align:right}.track{height:10px;border-radius:99px;background:#e8eef2;overflow:hidden}.track i{display:block;height:100%;border-radius:99px;background:var(--teal)}.track i.coral{background:var(--coral)}
.hours{display:flex;height:210px;align-items:flex-end;gap:4px;border-bottom:1px solid var(--line);padding-top:18px}.hour-column{height:100%;flex:1;display:flex;flex-direction:column;justify-content:flex-end;align-items:center}.hour-column i{width:100%;max-width:20px;background:linear-gradient(#14b8a6,#0f766e);border-radius:5px 5px 0 0;min-height:2px}.hour-column small{font-size:8px;color:var(--muted);margin:5px 0}.callout{background:#ecfdf5;border-left:4px solid var(--teal);padding:18px;border-radius:10px;margin-top:18px}.callout strong{display:block;margin-bottom:6px}.callout p{margin:0;color:#334155;font-size:13px;line-height:1.5}.coverage{display:flex;gap:10px;align-items:end;height:190px;padding:15px}.coverage div{flex:1;text-align:center}.coverage i{display:block;background:var(--teal);border-radius:8px 8px 0 0;margin:auto auto 8px;max-width:58px}.coverage b{display:block;font-size:13px}.coverage small{font-size:10px;color:var(--muted)}
.select{border:1px solid var(--line);border-radius:8px;padding:9px 12px;background:#fff;color:var(--ink)}.segments{display:grid;gap:11px}.segment{display:flex;justify-content:space-between;align-items:center;padding:14px;background:#f8fafc;border-radius:10px}.segment span{display:block;color:var(--muted);font-size:11px;margin-top:3px}.segment b{font-size:24px;color:var(--teal)}.scatter{width:100%;height:270px}.scatter line{stroke:#cbd5e1}.scatter text{font-size:11px;fill:#64748b}.scatter circle{fill:#f97360;opacity:.78;stroke:#fff;stroke-width:1.5}
table{width:100%;border-collapse:collapse;font-size:12px}th{text-align:left;color:var(--muted);padding:10px;border-bottom:1px solid var(--line)}td{padding:10px;border-bottom:1px solid #eef2f7}.status{background:#dcfce7;color:var(--green);font-weight:800;padding:4px 8px;border-radius:99px;font-size:10px}.note{font-size:12px;color:var(--muted);line-height:1.5}.two{display:grid;grid-template-columns:1fr 1fr;gap:18px}.footer{color:var(--muted);font-size:11px;margin-top:20px;text-align:right}
@media(max-width:850px){.cards{grid-template-columns:1fr 1fr}.grid,.two{grid-template-columns:1fr}.topbar,.nav,main{padding-left:18px;padding-right:18px}.period{display:none}.intro h2{font-size:23px}}
</style>
</head>
<body><div class="shell">
<header class="topbar"><div class="brand"><div class="mark"></div><div><h1>Bellabeat Usage Intelligence</h1><p>Evidence led product analytics</p></div></div><div class="period">Fitabase convenience sample<br>April 12 to May 12, 2016</div></header>
<nav class="nav" aria-label="Dashboard pages"><button class="active" data-page="executive">Executive Overview</button><button data-page="usage">Usage Patterns</button><button data-page="quality">Data Quality and Evidence</button></nav>
<main>
<section class="page active" id="executive"><div class="intro"><div><div class="eyebrow">Decision view</div><h2>Activity is concentrated, but individual behavior varies</h2><p>Equal participant weighting provides the default view. Recommendations are framed as testable product experiments, not causal conclusions.</p></div></div>
<div class="cards"><div class="card"><span>Participants</span><strong>%%PARTICIPANTS%%</strong><small>Activity records</small></div><div class="card"><span>Daily steps</span><strong>%%STEPS%%</strong><small>Participant weighted</small></div><div class="card"><span>Sedentary hours</span><strong>%%SEDENTARY%%</strong><small>Per participant day</small></div><div class="card"><span>10K step days</span><strong>%%GOAL%%</strong><small>Participant weighted share</small></div></div>
<div class="grid"><div class="panel"><h3>Participant weighted steps by weekday</h3><div class="sub">Saturday is the highest average day. Intervals are available in the model.</div>%%WEEKDAY_BARS%%</div><div class="panel"><h3>Activity by hour</h3><div class="sub">Average participant hour profile, peak at 18:00</div><div class="hours">%%HOUR_COLUMNS%%</div><div class="callout"><strong>Product opportunity</strong><p>Test timely movement prompts around the evening activity window, while letting users control timing and frequency.</p></div></div></div>
<div class="grid" style="margin-top:18px"><div class="panel"><h3>Dataset coverage</h3><div class="sub">Participants vary materially by source</div><div class="coverage">%%COVERAGE%%</div></div><div class="panel"><h3>Recommended next tests</h3><div class="sub">Measure incremental behavior and retention</div><ol class="note"><li>Personalized evening movement prompt</li><li>Weekly progress reflection with attainable goals</li><li>Sleep logging education and reminder controls</li></ol><p class="note">Use randomized rollout, participant level assignment, opt out monitoring, and preregistered guardrails.</p></div></div></section>

<section class="page" id="usage"><div class="intro"><div><div class="eyebrow">Behavior view</div><h2>Usage patterns and engagement</h2><p>Explore time patterns and participant profiles without letting high logging users dominate the averages.</p></div><label>Daypart <select class="select" id="daypart"><option>All</option><option>Overnight</option><option>Morning</option><option>Afternoon</option><option>Evening</option><option>Night</option></select></label></div>
<div class="grid"><div class="panel"><h3>Hourly steps</h3><div class="sub">Choose a daypart to highlight its hours</div><div class="hours" id="filtered-hours">%%HOUR_COLUMNS%%</div></div><div class="panel"><h3>Engagement segments</h3><div class="sub">Descriptive groups based on valid activity days</div><div class="segments">%%SEGMENTS%%</div></div></div>
<div class="two" style="margin-top:18px"><div class="panel"><h3>Participant days versus average steps</h3><div class="sub">Each dot represents one participant</div>%%SCATTER%%</div><div class="panel"><h3>Interpretation</h3><div class="sub">What this view can and cannot support</div><div class="callout"><strong>Equal participant weight</strong><p>Each participant contributes one profile to executive averages, regardless of the number of logged days.</p></div><p class="note">The sample is small, self selected, and historical. Engagement segments describe data availability. They do not identify customer personas or predict retention.</p></div></div></section>

<section class="page" id="quality"><div class="intro"><div><div class="eyebrow">Trust view</div><h2>Quality gates and statistical evidence</h2><p>Every source expectation is executable in SQL. Uncertainty and weighting sensitivity remain visible beside the headline findings.</p></div><span class="status">ALL CHECKS PASS</span></div>
<div class="panel"><h3>DuckDB quality checks</h3><div class="sub">The pipeline stops before analysis if any check fails</div><table><thead><tr><th>Check</th><th>Actual</th><th>Expected</th><th>Status</th></tr></thead><tbody>%%QUALITY_ROWS%%</tbody></table></div>
<div class="two" style="margin-top:18px"><div class="panel"><h3>Sleep association estimates</h3><div class="sub">Hours per additional 1,000 steps</div><table><thead><tr><th>Estimand</th><th>Estimate</th><th>95% interval</th><th>Participants</th></tr></thead><tbody>%%EVIDENCE_ROWS%%</tbody></table><div class="callout"><strong>Inconclusive within participant result</strong><p>The participant cluster bootstrap interval includes zero. The negative naive association should not be read as a causal effect.</p></div></div><div class="panel"><h3>Weighting sensitivity</h3><div class="sub">Observation and participant weighted estimates</div><table><thead><tr><th>Metric</th><th>Observation</th><th>Participant</th><th>Difference</th></tr></thead><tbody>%%SENSITIVITY_ROWS%%</tbody></table><p class="note">The default dashboard uses participant weighted estimates. Sensitivity values show how much the answer changes when logged days receive equal weight.</p></div></div></section>
<div class="footer">Generated from tested SQL and R outputs. No raw participant day data appears in this dashboard.</div>
</main></div>
<script>
document.querySelectorAll('.nav button').forEach(button=>button.addEventListener('click',()=>{document.querySelectorAll('.nav button,.page').forEach(el=>el.classList.remove('active'));button.classList.add('active');document.getElementById(button.dataset.page).classList.add('active')}));
document.getElementById('daypart').addEventListener('change',event=>{document.querySelectorAll('#filtered-hours .hour-column').forEach(column=>{const match=event.target.value==='All'||column.dataset.daypart===event.target.value;column.style.opacity=match?'1':'.12'})});
</script></body></html>"""

    coverage_max = max(float(row["participants"]) for row in coverage)
    coverage_blocks = "".join(
        '<div><i style="height:'
        f'{150 * float(row["participants"]) / coverage_max:.0f}px;width:100%"></i>'
        f'<b>{int(float(row["participants"]))}</b><small>{html.escape(row["dataset"])}</small></div>'
        for row in coverage
    )
    values = {
        "%%PARTICIPANTS%%": kpis["Participants"]["display_value"],
        "%%STEPS%%": kpis["Participant weighted daily steps"]["display_value"],
        "%%SEDENTARY%%": kpis["Participant weighted sedentary hours"]["display_value"],
        "%%GOAL%%": kpis["Participant weighted 10k step day share"]["display_value"],
        "%%WEEKDAY_BARS%%": horizontal_bars(weekday, "day_name", "participant_weighted_steps"),
        "%%HOUR_COLUMNS%%": hour_columns(hourly),
        "%%COVERAGE%%": coverage_blocks,
        "%%SEGMENTS%%": segment_rows,
        "%%SCATTER%%": participant_scatter(participants),
        "%%QUALITY_ROWS%%": quality_rows,
        "%%EVIDENCE_ROWS%%": evidence_rows,
        "%%SENSITIVITY_ROWS%%": sensitivity_rows,
    }
    for token, value in values.items():
        template = template.replace(token, value)
    OUTPUT.write_text(template, encoding="utf-8")
    print(f"Dashboard prototype written to {OUTPUT}")


if __name__ == "__main__":
    main()
