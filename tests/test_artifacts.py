"""Validate the SQL, dashboard, and executive reporting artifacts."""

from __future__ import annotations

import csv
from pathlib import Path

from PIL import Image
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]


def csv_rows(path: Path) -> list[dict[str, str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle))


def main() -> None:
    sql_files = sorted((ROOT / "sql").glob("*.sql"))
    assert len(sql_files) == 7
    sql_text = "\n".join(path.read_text(encoding="utf-8") for path in sql_files).lower()
    for construct in ["row_number() over", "inner join", "with typed as", "create or replace view"]:
        assert construct in sql_text, construct

    quality = csv_rows(ROOT / "data" / "processed" / "sql_quality_checks.csv")
    assert len(quality) == 12
    assert all(row["passed"].lower() == "true" for row in quality)

    sql_kpis = csv_rows(ROOT / "data" / "processed" / "sql_participant_kpis.csv")
    assert len(sql_kpis) == 33
    sql_steps = sum(float(row["avg_steps"]) for row in sql_kpis) / len(sql_kpis)
    r_metrics = csv_rows(ROOT / "data" / "processed" / "summary_participant_metrics.csv")
    r_steps = float(next(row for row in r_metrics if row["metric"] == "Average daily steps")["estimate"])
    assert abs(sql_steps - r_steps) < 0.0001

    powerbi_dir = ROOT / "powerbi" / "data"
    expected_tables = {
        "participant_summary.csv": 33,
        "executive_kpis.csv": 4,
        "weekday_activity.csv": 7,
        "hourly_activity.csv": 24,
        "coverage.csv": 4,
        "engagement_segments.csv": 3,
        "evidence.csv": 3,
        "sensitivity.csv": 3,
        "data_quality.csv": 12,
    }
    for filename, expected_rows in expected_tables.items():
        assert len(csv_rows(powerbi_dir / filename)) == expected_rows, filename

    dashboard = (ROOT / "powerbi" / "dashboard.html").read_text(encoding="utf-8")
    for page in ["Executive Overview", "Usage Patterns", "Data Quality and Evidence"]:
        assert page in dashboard
    assert "ALL CHECKS PASS" in dashboard
    assert "https://" not in dashboard

    preview = ROOT / "powerbi" / "dashboard-preview.png"
    with Image.open(preview) as image:
        assert image.width >= 1200 and image.height >= 700

    brief = PdfReader(ROOT / "docs" / "EXECUTIVE_BRIEF.pdf")
    assert len(brief.pages) == 1
    assert brief.metadata.author == "Kazmir Fahrier"
    brief_text = brief.pages[0].extract_text().lower()
    for section in ["business question", "what the evidence says", "decision limits", "quality gate: pass"]:
        assert section in brief_text, section

    assert not list(ROOT.rglob("*.pbix"))
    print("SQL, Power BI, dashboard, and executive brief checks passed.")


if __name__ == "__main__":
    main()
