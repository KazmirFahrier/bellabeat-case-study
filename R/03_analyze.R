# =============================================================================
# 03_analyze.R
# Summarise Bellabeat-relevant smart device usage trends
# =============================================================================

library(tidyverse)
library(here)
library(scales)

daily <- readRDS(here("data", "processed", "daily_enriched.rds"))
hourly <- readRDS(here("data", "processed", "hourly_enriched.rds"))
coverage <- read_csv(
  here("data", "processed", "summary_dataset_coverage.csv"),
  show_col_types = FALSE
)

overview <- tibble(
  metric = c(
    "activity_users",
    "sleep_users",
    "weight_users",
    "date_range_start",
    "date_range_end",
    "avg_daily_steps",
    "median_daily_steps",
    "avg_daily_calories",
    "avg_daily_active_minutes",
    "avg_daily_sedentary_hours",
    "share_days_meeting_10k_steps",
    "share_days_with_sleep_logs",
    "avg_sleep_hours_logged_days"
  ),
  value = c(
    n_distinct(daily$id),
    coverage$unique_users[coverage$dataset == "sleep_day"],
    coverage$unique_users[coverage$dataset == "weight_log"],
    as.character(min(daily$activity_date)),
    as.character(max(daily$activity_date)),
    round(mean(daily$total_steps), 1),
    round(median(daily$total_steps), 1),
    round(mean(daily$calories), 1),
    round(mean(daily$active_minutes), 1),
    round(mean(daily$sedentary_hours), 2),
    round(mean(daily$step_goal_achieved), 3),
    round(mean(daily$sleep_logged), 3),
    round(mean(daily$sleep_hours[daily$sleep_logged], na.rm = TRUE), 2)
  )
)

engagement_segments <- daily |>
  distinct(id, engagement_segment, days_logged) |>
  group_by(engagement_segment) |>
  summarise(
    users = n(),
    avg_days_logged = mean(days_logged),
    .groups = "drop"
  ) |>
  mutate(share_of_users = users / sum(users))

weekday_summary <- daily |>
  group_by(day_of_week) |>
  summarise(
    avg_steps = mean(total_steps),
    avg_calories = mean(calories),
    avg_active_minutes = mean(active_minutes),
    step_goal_rate = mean(step_goal_achieved),
    sleep_log_rate = mean(sleep_logged),
    .groups = "drop"
  )

hourly_summary <- hourly |>
  group_by(hour_of_day) |>
  summarise(
    avg_steps = mean(step_total),
    avg_total_intensity = mean(total_intensity),
    avg_calories = mean(calories),
    .groups = "drop"
  )

sleep_by_steps <- daily |>
  filter(sleep_logged) |>
  group_by(step_bucket) |>
  summarise(
    days = n(),
    avg_sleep_hours = mean(sleep_hours),
    avg_steps = mean(total_steps),
    .groups = "drop"
  )

activity_mix <- daily |>
  summarise(
    sedentary_minutes = mean(sedentary_minutes),
    lightly_active_minutes = mean(lightly_active_minutes),
    fairly_active_minutes = mean(fairly_active_minutes),
    very_active_minutes = mean(very_active_minutes)
  ) |>
  pivot_longer(everything(), names_to = "activity_type", values_to = "avg_minutes") |>
  mutate(
    activity_type = factor(
      activity_type,
      levels = c(
        "sedentary_minutes",
        "lightly_active_minutes",
        "fairly_active_minutes",
        "very_active_minutes"
      ),
      labels = c(
        "Sedentary",
        "Lightly active",
        "Fairly active",
        "Very active"
      )
    )
  )

segment_summary <- daily |>
  group_by(engagement_segment) |>
  summarise(
    avg_steps = mean(total_steps),
    avg_calories = mean(calories),
    sleep_log_rate = mean(sleep_logged),
    avg_sleep_hours = mean(sleep_hours, na.rm = TRUE),
    .groups = "drop"
  )

write_csv(overview, here("data", "processed", "summary_overview.csv"))
write_csv(engagement_segments, here("data", "processed", "summary_engagement_segments.csv"))
write_csv(weekday_summary, here("data", "processed", "summary_weekday_usage.csv"))
write_csv(hourly_summary, here("data", "processed", "summary_hourly_usage.csv"))
write_csv(sleep_by_steps, here("data", "processed", "summary_sleep_by_steps.csv"))
write_csv(activity_mix, here("data", "processed", "summary_activity_mix.csv"))
write_csv(segment_summary, here("data", "processed", "summary_by_segment.csv"))

message("Analysis complete. Summary CSVs written to data/processed/")
