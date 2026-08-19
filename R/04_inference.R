# Participant aware inference, uncertainty, and sensitivity analysis.

library(here)
library(tidyverse)

daily <- readRDS(here("data", "processed", "daily_enriched.rds"))
hourly <- readRDS(here("data", "processed", "hourly_enriched.rds"))

bootstrap_iterations <- 2000
bootstrap_seed <- 20260819

participant_daily <- daily |>
  group_by(id) |>
  summarise(
    days_logged = n(),
    avg_steps = mean(total_steps),
    avg_active_minutes = mean(active_minutes),
    avg_sedentary_hours = mean(sedentary_hours),
    step_goal_rate = mean(step_goal_achieved),
    sleep_log_rate = mean(sleep_logged),
    .groups = "drop"
  )

participant_metrics <- tribble(
  ~metric, ~column,
  "Average daily steps", "avg_steps",
  "Average active minutes", "avg_active_minutes",
  "Average sedentary hours", "avg_sedentary_hours",
  "Share of days reaching 10k steps", "step_goal_rate",
  "Share of days with sleep logs", "sleep_log_rate"
) |>
  mutate(
    estimate = map_dbl(column, ~ mean(participant_daily[[.x]], na.rm = TRUE)),
    interval = map2(
      column,
      row_number(),
      ~ bootstrap_mean(
        participant_daily[[.x]],
        iterations = bootstrap_iterations,
        seed = bootstrap_seed + .y
      )
    ),
    ci_low = map_dbl(interval, "low"),
    ci_high = map_dbl(interval, "high"),
    participants = nrow(participant_daily)
  ) |>
  select(-column, -interval)

weekday_user <- daily |>
  group_by(id, day_of_week) |>
  summarise(avg_steps = mean(total_steps), .groups = "drop")

weekday_participant <- weekday_user |>
  group_by(day_of_week) |>
  summarise(
    participant_values = list(avg_steps),
    participants = n(),
    .groups = "drop"
  ) |>
  mutate(
    avg_steps = map_dbl(participant_values, mean),
    ci = map2(
      participant_values,
      as.integer(day_of_week),
      ~
      bootstrap_mean(
        .x,
        iterations = bootstrap_iterations,
        seed = bootstrap_seed + .y
      )
    ),
    ci_low = map_dbl(ci, "low"),
    ci_high = map_dbl(ci, "high")
  ) |>
  select(-participant_values, -ci)

hourly_user <- hourly |>
  group_by(id, hour_of_day) |>
  summarise(avg_steps = mean(step_total), .groups = "drop")

hourly_participant <- hourly_user |>
  group_by(hour_of_day) |>
  summarise(
    participant_values = list(avg_steps),
    participants = n(),
    .groups = "drop"
  ) |>
  mutate(
    avg_steps = map_dbl(participant_values, mean),
    ci = map2(
      participant_values,
      hour_of_day,
      ~
      bootstrap_mean(
        .x,
        iterations = bootstrap_iterations,
        seed = bootstrap_seed + .y + 20
      )
    ),
    ci_low = map_dbl(ci, "low"),
    ci_high = map_dbl(ci, "high")
  ) |>
  select(-participant_values, -ci)

sleep_matched <- daily |>
  filter(sleep_logged) |>
  add_count(id, name = "sleep_days") |>
  filter(sleep_days >= 5) |>
  group_by(id) |>
  mutate(
    within_steps_1000 = (total_steps - mean(total_steps)) / 1000
  ) |>
  ungroup()

naive_sleep_model <- lm(sleep_hours ~ I(total_steps / 1000), data = sleep_matched)
within_sleep_model <- lm(sleep_hours ~ within_steps_1000 + factor(id), data = sleep_matched)

sleep_users <- unique(sleep_matched$id)
set.seed(bootstrap_seed)
within_bootstrap <- replicate(bootstrap_iterations, {
  sampled_users <- sample(sleep_users, length(sleep_users), replace = TRUE)
  boot_data <- map2_dfr(sampled_users, seq_along(sampled_users), function(user_id, draw_id) {
    sleep_matched |>
      filter(id == user_id) |>
      mutate(bootstrap_id = factor(draw_id))
  })
  model <- tryCatch(
    lm(sleep_hours ~ within_steps_1000 + bootstrap_id, data = boot_data),
    error = function(error) NULL
  )
  if (is.null(model)) NA_real_ else safe_coefficient(model, "within_steps_1000")
})
within_bootstrap <- within_bootstrap[is.finite(within_bootstrap)]

sleep_user_means <- sleep_matched |>
  group_by(id) |>
  summarise(
    avg_sleep_hours = mean(sleep_hours),
    avg_steps_1000 = mean(total_steps) / 1000,
    .groups = "drop"
  )
between_sleep_model <- lm(avg_sleep_hours ~ avg_steps_1000, data = sleep_user_means)

naive_interval <- confint(naive_sleep_model, "I(total_steps/1000)")
within_interval <- quantile(within_bootstrap, c(0.025, 0.975), names = FALSE)
between_interval <- confint(between_sleep_model, "avg_steps_1000")

sleep_association <- tibble(
  estimand = c(
    "Naive day level association",
    "Within participant association",
    "Between participant association"
  ),
  estimate_hours_per_1000_steps = c(
    safe_coefficient(naive_sleep_model, "I(total_steps/1000)"),
    safe_coefficient(within_sleep_model, "within_steps_1000"),
    safe_coefficient(between_sleep_model, "avg_steps_1000")
  ),
  ci_low = c(naive_interval[1], within_interval[1], between_interval[1]),
  ci_high = c(naive_interval[2], within_interval[2], between_interval[2]),
  participants = c(n_distinct(sleep_matched$id), n_distinct(sleep_matched$id), nrow(sleep_user_means)),
  observations = c(nrow(sleep_matched), nrow(sleep_matched), nrow(sleep_user_means)),
  method = c(
    "Ordinary least squares; repeated days treated as independent",
    "Participant fixed effects with participant cluster bootstrap",
    "Regression of participant level means"
  )
)

estimand_sensitivity <- tibble(
  metric = c("Average daily steps", "Average sedentary hours", "10k step day share"),
  observation_weighted = c(
    mean(daily$total_steps),
    mean(daily$sedentary_hours),
    mean(daily$step_goal_achieved)
  ),
  participant_weighted = c(
    mean(participant_daily$avg_steps),
    mean(participant_daily$avg_sedentary_hours),
    mean(participant_daily$step_goal_rate)
  )
) |>
  mutate(difference = participant_weighted - observation_weighted)

participant_coverage <- daily |>
  group_by(id) |>
  summarise(
    activity_days = n(),
    sleep_days = sum(sleep_logged),
    weight_days = sum(weight_logged),
    sleep_coverage = mean(sleep_logged),
    weight_coverage = mean(weight_logged),
    .groups = "drop"
  )

missingness <- tibble(
  metric = c(
    "Daily activity observations",
    "Participants with activity",
    "Daily observations with sleep",
    "Participants with sleep",
    "Daily observations with weight",
    "Participants with weight"
  ),
  value = c(
    nrow(daily),
    n_distinct(daily$id),
    sum(daily$sleep_logged),
    sum(participant_coverage$sleep_days > 0),
    sum(daily$weight_logged),
    sum(participant_coverage$weight_days > 0)
  )
)

product_experiments <- tribble(
  ~hypothesis, ~intervention, ~primary_metric, ~guardrail, ~design,
  "Routine timed prompts increase meaningful movement",
  "Personalized prompt near each user's historically active midday or evening window",
  "Incremental active minutes per user day",
  "Prompt opt out rate",
  "Randomized user level trial with a neutral notification control",
  "A combined movement and recovery summary improves weekly engagement",
  "Weekly summary that pairs movement consistency with sleep logging",
  "Four week retained weekly active users",
  "Notification dismissals and sleep tracking opt outs",
  "Randomized user level trial stratified by baseline engagement",
  "Passive defaults increase sleep coverage without reducing trust",
  "Clear opt in sleep tracking setup with a privacy explanation",
  "Share of eligible nights with a sleep record",
  "Consent abandonment and feature disablement",
  "Staged experiment with privacy review and explicit consent"
)

round_numeric <- function(data, digits = 6) {
  data |>
    mutate(across(where(is.numeric), ~ round(.x, digits)))
}

write_csv(round_numeric(participant_metrics), here("data", "processed", "summary_participant_metrics.csv"))
write_csv(round_numeric(weekday_participant), here("data", "processed", "summary_weekday_participant.csv"))
write_csv(round_numeric(hourly_participant), here("data", "processed", "summary_hourly_participant.csv"))
write_csv(round_numeric(sleep_association), here("data", "processed", "summary_sleep_association.csv"))
write_csv(round_numeric(estimand_sensitivity), here("data", "processed", "summary_estimand_sensitivity.csv"))
write_csv(round_numeric(participant_coverage), here("data", "processed", "participant_coverage.csv"))
write_csv(missingness, here("data", "processed", "summary_missingness.csv"))
write_csv(product_experiments, here("data", "processed", "product_experiments.csv"))

message("Participant aware inference and clustered uncertainty complete.")
