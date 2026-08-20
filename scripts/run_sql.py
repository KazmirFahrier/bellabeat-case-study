"""Build and validate the local DuckDB analytical warehouse."""

from __future__ import annotations

from pathlib import Path

import duckdb


ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"
WAREHOUSE_DIR = ROOT / "data" / "warehouse"
PROCESSED_DIR = ROOT / "data" / "processed"
DATABASE_PATH = WAREHOUSE_DIR / "bellabeat.duckdb"


def sql_literal(path: Path) -> str:
    """Return a safely quoted DuckDB string literal for a local path."""
    return "'" + str(path).replace("'", "''") + "'"


def export_csv(connection: duckdb.DuckDBPyConnection, query: str, path: Path) -> None:
    """Export a deterministic query result to CSV."""
    connection.execute(
        f"COPY ({query}) TO {sql_literal(path)} (HEADER, DELIMITER ',', QUOTE '\"')"
    )


def main() -> None:
    """Execute the SQL model, enforce quality gates, and export curated tables."""
    WAREHOUSE_DIR.mkdir(parents=True, exist_ok=True)
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    connection = duckdb.connect(str(DATABASE_PATH))
    try:
        connection.execute(f"SET home_directory={sql_literal(ROOT)}")
        for sql_path in sorted(SQL_DIR.glob("*.sql")):
            connection.execute(sql_path.read_text(encoding="utf-8"))

        failed = connection.execute(
            "SELECT check_name, actual_value, expected_value "
            "FROM vw_quality_checks WHERE NOT passed ORDER BY check_name"
        ).fetchall()
        if failed:
            details = "; ".join(
                f"{name}: actual={actual}, expected={expected}"
                for name, actual, expected in failed
            )
            raise RuntimeError(f"DuckDB quality checks failed: {details}")

        warehouse_exports = {
            "fact_daily_activity.csv": "SELECT * FROM fact_daily_activity ORDER BY participant_id, activity_date",
            "fact_daily_sleep.csv": "SELECT * FROM fact_daily_sleep ORDER BY participant_id, sleep_date",
            "fact_weight.csv": "SELECT * FROM fact_weight ORDER BY participant_id, weight_date",
            "fact_hourly_activity.csv": "SELECT * FROM fact_hourly_activity ORDER BY participant_id, activity_hour",
        }
        for filename, query in warehouse_exports.items():
            export_csv(connection, query, WAREHOUSE_DIR / filename)

        processed_exports = {
            "sql_quality_checks.csv": "SELECT * FROM vw_quality_checks ORDER BY check_name",
            "sql_participant_kpis.csv": "SELECT * FROM participant_kpis ORDER BY participant_id",
            "sql_dashboard_kpis.csv": "SELECT * FROM vw_dashboard_kpis ORDER BY display_order",
            "sql_coverage.csv": "SELECT * FROM vw_coverage ORDER BY display_order",
            "sql_engagement_segments.csv": "SELECT * FROM vw_engagement_segments ORDER BY engagement_segment",
            "sql_weekday_usage.csv": "SELECT * FROM vw_weekday_usage ORDER BY iso_day_number",
            "sql_hourly_usage.csv": "SELECT * FROM vw_hourly_usage ORDER BY hour_of_day",
            "sql_estimand_sensitivity.csv": "SELECT *, participant_weighted - observation_weighted AS difference FROM vw_estimand_sensitivity ORDER BY metric",
            "sql_business_rules.csv": "SELECT * FROM vw_business_rules ORDER BY metric_name",
        }
        for filename, query in processed_exports.items():
            export_csv(connection, query, PROCESSED_DIR / filename)
    finally:
        connection.close()

    print("DuckDB warehouse built and all SQL quality checks passed.")


if __name__ == "__main__":
    main()
