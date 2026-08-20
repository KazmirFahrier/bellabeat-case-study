# Export compact, documented tables for the Power BI semantic model.

library(here)
library(tidyverse)

powerbi_data <- here("powerbi", "data")
dir.create(powerbi_data, recursive = TRUE, showWarnings = FALSE)

read_processed <- function(filename) {
  read_csv(here("data", "processed", filename), show_col_types = FALSE)
}

participant_summary <- read_processed("sql_participant_kpis.csv")
executive_kpis <- read_processed("sql_dashboard_kpis.csv")
coverage <- read_processed("sql_coverage.csv")
engagement_segments <- read_processed("sql_engagement_segments.csv")
data_quality <- read_processed("sql_quality_checks.csv")
evidence <- read_processed("summary_sleep_association.csv")
sensitivity <- read_processed("summary_estimand_sensitivity.csv")

weekday_activity <- read_processed("sql_weekday_usage.csv") |>
  left_join(
    read_processed("summary_weekday_participant.csv") |>
      select(day_name = day_of_week, ci_low_steps = ci_low, ci_high_steps = ci_high),
    by = "day_name"
  )

hourly_activity <- read_processed("sql_hourly_usage.csv") |>
  left_join(
    read_processed("summary_hourly_participant.csv") |>
      select(hour_of_day, ci_low_steps = ci_low, ci_high_steps = ci_high),
    by = "hour_of_day"
  )

exports <- list(
  "participant_summary.csv" = participant_summary,
  "executive_kpis.csv" = executive_kpis,
  "weekday_activity.csv" = weekday_activity,
  "hourly_activity.csv" = hourly_activity,
  "coverage.csv" = coverage,
  "engagement_segments.csv" = engagement_segments,
  "evidence.csv" = evidence,
  "sensitivity.csv" = sensitivity,
  "data_quality.csv" = data_quality
)

walk2(exports, names(exports), function(data, filename) {
  write_csv(data, file.path(powerbi_data, filename), na = "")
})

message("Power BI import tables written to powerbi/data/.")
