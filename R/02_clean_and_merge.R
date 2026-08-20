# Read the DuckDB curated layer and create R analysis tables.

library(here)
library(lubridate)
library(tidyverse)

warehouse_dir <- here("data", "warehouse")

daily_activity <- read_csv(
  file.path(warehouse_dir, "fact_daily_activity.csv"),
  col_types = cols(
    participant_id = col_character(),
    activity_date = col_date()
  )
) |>
  rename(id = participant_id)

sleep_day <- read_csv(
  file.path(warehouse_dir, "fact_daily_sleep.csv"),
  col_types = cols(
    participant_id = col_character(),
    sleep_date = col_date()
  )
) |>
  rename(id = participant_id)

weight_log <- read_csv(
  file.path(warehouse_dir, "fact_weight.csv"),
  col_types = cols(
    participant_id = col_character(),
    weight_date = col_date()
  )
) |>
  rename(id = participant_id)

hourly_activity <- read_csv(
  file.path(warehouse_dir, "fact_hourly_activity.csv"),
  col_types = cols(
    participant_id = col_character(),
    activity_hour = col_datetime()
  )
) |>
  rename(id = participant_id)

assert_columns(
  daily_activity,
  c(
    "id", "activity_date", "total_steps", "calories", "sedentary_minutes",
    "lightly_active_minutes", "fairly_active_minutes", "very_active_minutes",
    "active_minutes", "sedentary_hours", "step_goal_achieved", "step_bucket"
  ),
  "daily activity"
)
assert_unique_key(daily_activity, c("id", "activity_date"), "daily activity")
assert_unique_key(sleep_day, c("id", "sleep_date"), "sleep day")
assert_unique_key(weight_log, c("id", "weight_date"), "weight log")
assert_unique_key(hourly_activity, c("id", "activity_hour"), "hourly activity")

activity_users <- n_distinct(daily_activity$id)
sleep_users <- n_distinct(sleep_day$id)
weight_users <- n_distinct(weight_log$id)

coverage <- tibble(
  dataset = c(
    "daily_activity", "sleep_day", "weight_log", "hourly_steps",
    "hourly_intensities", "hourly_calories"
  ),
  unique_users = c(
    activity_users,
    sleep_users,
    weight_users,
    n_distinct(hourly_activity$id),
    n_distinct(hourly_activity$id),
    n_distinct(hourly_activity$id)
  )
)

engagement_by_user <- daily_activity |>
  count(id, name = "days_logged") |>
  mutate(
    engagement_segment = case_when(
      days_logged <= 10 ~ "Low (1-10 days)",
      days_logged <= 24 ~ "Moderate (11-24 days)",
      TRUE ~ "High (25+ days)"
    )
  )

daily_enriched <- daily_activity |>
  left_join(sleep_day, by = c("id", "activity_date" = "sleep_date")) |>
  left_join(weight_log, by = c("id", "activity_date" = "weight_date")) |>
  left_join(engagement_by_user, by = "id") |>
  mutate(
    day_of_week = wday(activity_date, label = TRUE, abbr = FALSE, week_start = 1),
    week_part = if_else(day_of_week %in% c("Saturday", "Sunday"), "Weekend", "Weekday"),
    sleep_hours = total_minutes_asleep / 60,
    sleep_logged = !is.na(total_minutes_asleep),
    weight_logged = !is.na(weight_kg),
    step_bucket = factor(
      step_bucket,
      levels = c("Under 5k", "5k-7.4k", "7.5k-9.9k", "10k+")
    )
  )

hourly_enriched <- hourly_activity |>
  mutate(
    day_of_week = wday(activity_hour, label = TRUE, abbr = FALSE, week_start = 1),
    week_part = if_else(day_of_week %in% c("Saturday", "Sunday"), "Weekend", "Weekday")
  )

if (
  n_distinct(daily_activity$id) != 33 ||
    min(daily_activity$activity_date) != as.Date("2016-04-12") ||
    max(daily_activity$activity_date) != as.Date("2016-05-12")
) {
  stop("Daily activity does not match the verified source snapshot.", call. = FALSE)
}

sql_quality <- read_csv(
  here("data", "processed", "sql_quality_checks.csv"),
  show_col_types = FALSE
)
if (!all(sql_quality$passed)) {
  stop("One or more DuckDB quality checks failed.", call. = FALSE)
}

quality_value <- function(check_name) {
  sql_quality$actual_value[sql_quality$check_name == check_name]
}

data_quality <- tibble(
  check = c(
    "daily_rows",
    "daily_source_rows",
    "daily_rows_excluded",
    "daily_users",
    "sleep_source_rows",
    "sleep_user_days",
    "sleep_rows_consolidated",
    "sleep_users",
    "weight_user_days",
    "weight_users",
    "hourly_rows",
    "daily_start",
    "daily_end"
  ),
  value = c(
    quality_value("daily_valid_rows"),
    quality_value("daily_source_rows"),
    quality_value("daily_source_rows") - quality_value("daily_valid_rows"),
    quality_value("daily_participants"),
    quality_value("sleep_source_rows"),
    quality_value("sleep_user_days"),
    quality_value("sleep_duplicate_rows"),
    quality_value("sleep_participants"),
    quality_value("weight_user_days"),
    quality_value("weight_participants"),
    quality_value("hourly_join_rows"),
    as.character(min(daily_activity$activity_date)),
    as.character(max(daily_activity$activity_date))
  )
)

saveRDS(daily_enriched, here("data", "processed", "daily_enriched.rds"))
saveRDS(hourly_enriched, here("data", "processed", "hourly_enriched.rds"))
write_csv(coverage, here("data", "processed", "summary_dataset_coverage.csv"))
write_csv(engagement_by_user, here("data", "processed", "user_engagement_days.csv"))
write_csv(data_quality, here("data", "processed", "summary_data_quality.csv"))

message("Loaded DuckDB curated tables and saved R analysis tables.")
