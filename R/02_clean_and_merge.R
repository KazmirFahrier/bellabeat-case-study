# =============================================================================
# 02_clean_and_merge.R
# Clean Fitabase files and create daily + hourly analysis tables
# =============================================================================

library(tidyverse)
library(lubridate)
library(here)
library(janitor)

raw_dir <- here("data", "raw")

daily_raw <- read_csv(
  file.path(raw_dir, "dailyActivity_merged.csv"),
  show_col_types = FALSE
) |>
  clean_names()

daily_activity <- daily_raw |>
  transmute(
    id = as.character(id),
    activity_date = mdy(activity_date),
    total_steps,
    total_distance,
    calories,
    sedentary_minutes,
    lightly_active_minutes,
    fairly_active_minutes,
    very_active_minutes
  ) |>
  distinct() |>
  filter(
    !is.na(activity_date),
    total_steps >= 0,
    calories > 0
  )

assert_columns(
  daily_activity,
  c(
    "id", "activity_date", "total_steps", "calories", "sedentary_minutes",
    "lightly_active_minutes", "fairly_active_minutes", "very_active_minutes"
  ),
  "daily activity"
)
assert_unique_key(daily_activity, c("id", "activity_date"), "daily activity")

sleep_raw <- read_csv(
  file.path(raw_dir, "sleepDay_merged.csv"),
  show_col_types = FALSE
) |>
  clean_names()

sleep_day <- sleep_raw |>
  transmute(
    id = as.character(id),
    sleep_datetime = mdy_hms(sleep_day),
    sleep_date = as_date(sleep_datetime),
    total_sleep_records,
    total_minutes_asleep,
    total_time_in_bed
  ) |>
  distinct() |>
  filter(!is.na(sleep_date)) |>
  group_by(id, sleep_date) |>
  summarise(
    total_sleep_records = mean(total_sleep_records),
    total_minutes_asleep = mean(total_minutes_asleep),
    total_time_in_bed = mean(total_time_in_bed),
    .groups = "drop"
  )

assert_columns(
  sleep_day,
  c("id", "sleep_date", "total_minutes_asleep", "total_time_in_bed"),
  "sleep day"
)
assert_unique_key(sleep_day, c("id", "sleep_date"), "sleep day")

weight_log <- read_csv(
  file.path(raw_dir, "weightLogInfo_merged.csv"),
  show_col_types = FALSE
) |>
  clean_names() |>
  transmute(
    id = as.character(id),
    weight_datetime = mdy_hms(date),
    weight_date = as_date(weight_datetime),
    weight_kg,
    bmi
  ) |>
  distinct() |>
  filter(!is.na(weight_date)) |>
  group_by(id, weight_date) |>
  summarise(
    weight_kg = mean(weight_kg, na.rm = TRUE),
    bmi = mean(bmi, na.rm = TRUE),
    .groups = "drop"
  )

assert_columns(weight_log, c("id", "weight_date", "weight_kg", "bmi"), "weight log")
assert_unique_key(weight_log, c("id", "weight_date"), "weight log")

hourly_steps <- read_csv(
  file.path(raw_dir, "hourlySteps_merged.csv"),
  show_col_types = FALSE
) |>
  clean_names() |>
  transmute(
    id = as.character(id),
    activity_hour = mdy_hms(activity_hour),
    step_total
  ) |>
  distinct()

hourly_intensities <- read_csv(
  file.path(raw_dir, "hourlyIntensities_merged.csv"),
  show_col_types = FALSE
) |>
  clean_names() |>
  transmute(
    id = as.character(id),
    activity_hour = mdy_hms(activity_hour),
    total_intensity,
    average_intensity
  ) |>
  distinct()

hourly_calories <- read_csv(
  file.path(raw_dir, "hourlyCalories_merged.csv"),
  show_col_types = FALSE
) |>
  clean_names() |>
  transmute(
    id = as.character(id),
    activity_hour = mdy_hms(activity_hour),
    calories
  ) |>
  distinct()

assert_unique_key(hourly_steps, c("id", "activity_hour"), "hourly steps")
assert_unique_key(hourly_intensities, c("id", "activity_hour"), "hourly intensities")
assert_unique_key(hourly_calories, c("id", "activity_hour"), "hourly calories")

activity_users <- n_distinct(daily_activity$id)
sleep_users <- n_distinct(sleep_day$id)
weight_users <- n_distinct(weight_log$id)

coverage <- tibble(
  dataset = c(
    "daily_activity",
    "sleep_day",
    "weight_log",
    "hourly_steps",
    "hourly_intensities",
    "hourly_calories"
  ),
  unique_users = c(
    activity_users,
    sleep_users,
    weight_users,
    n_distinct(hourly_steps$id),
    n_distinct(hourly_intensities$id),
    n_distinct(hourly_calories$id)
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
    active_minutes = lightly_active_minutes + fairly_active_minutes + very_active_minutes,
    sedentary_hours = sedentary_minutes / 60,
    sleep_hours = total_minutes_asleep / 60,
    step_goal_achieved = total_steps >= 10000,
    sleep_logged = !is.na(total_minutes_asleep),
    weight_logged = !is.na(weight_kg),
    step_bucket = case_when(
      total_steps < 5000 ~ "Under 5k",
      total_steps < 7500 ~ "5k-7.4k",
      total_steps < 10000 ~ "7.5k-9.9k",
      TRUE ~ "10k+"
    ),
    step_bucket = factor(
      step_bucket,
      levels = c("Under 5k", "5k-7.4k", "7.5k-9.9k", "10k+")
    )
  )

hourly_enriched <- hourly_steps |>
  inner_join(hourly_intensities, by = c("id", "activity_hour")) |>
  inner_join(hourly_calories, by = c("id", "activity_hour")) |>
  mutate(
    hour_of_day = hour(activity_hour),
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

if (nrow(hourly_enriched) != nrow(hourly_steps)) {
  stop("Hourly joins lost or duplicated rows.", call. = FALSE)
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
    nrow(daily_activity),
    nrow(daily_raw),
    nrow(daily_raw) - nrow(daily_activity),
    activity_users,
    nrow(sleep_raw),
    nrow(sleep_day),
    nrow(sleep_raw) - nrow(sleep_day),
    sleep_users,
    nrow(weight_log),
    weight_users,
    nrow(hourly_enriched),
    as.character(min(daily_activity$activity_date)),
    as.character(max(daily_activity$activity_date))
  )
)

saveRDS(daily_enriched, here("data", "processed", "daily_enriched.rds"))
saveRDS(hourly_enriched, here("data", "processed", "hourly_enriched.rds"))
write_csv(coverage, here("data", "processed", "summary_dataset_coverage.csv"))
write_csv(engagement_by_user, here("data", "processed", "user_engagement_days.csv"))
write_csv(data_quality, here("data", "processed", "summary_data_quality.csv"))

message("Saved cleaned analysis tables and coverage summaries.")
