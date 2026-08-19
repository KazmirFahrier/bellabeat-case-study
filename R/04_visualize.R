# =============================================================================
# 04_visualize.R
# Build polished charts for the Bellabeat report
# =============================================================================

library(tidyverse)
library(here)
library(scales)

fig_dir <- here("output", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

pal <- c(
  teal = "#0F766E",
  coral = "#F97360",
  gold = "#D4A017",
  slate = "#334155",
  mist = "#CBD5E1"
)

theme_bellabeat <- function() {
  theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "grey30", margin = margin(b = 10)),
      plot.caption = element_text(color = "grey50", size = 9, hjust = 0),
      legend.position = "top",
      legend.title = element_blank(),
      panel.grid.minor = element_blank()
    )
}

caption_txt <- "Source: Fitbit Fitabase data, Apr 12 2016 to May 12 2016"

save_fig <- function(plot, name, w = 9, h = 5.5) {
  ggsave(file.path(fig_dir, name), plot, width = w, height = h, dpi = 200, bg = "white")
}

coverage <- read_csv(here("data", "processed", "summary_dataset_coverage.csv"),
                     show_col_types = FALSE)
engagement <- read_csv(here("data", "processed", "summary_engagement_segments.csv"),
                       show_col_types = FALSE)
weekday <- read_csv(here("data", "processed", "summary_weekday_participant.csv"),
                    show_col_types = FALSE) |>
  mutate(
    day_of_week = factor(
      day_of_week,
      levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
    )
  )
hourly <- read_csv(here("data", "processed", "summary_hourly_participant.csv"),
                   show_col_types = FALSE)
sleep_association <- read_csv(here("data", "processed", "summary_sleep_association.csv"),
                              show_col_types = FALSE) |>
  filter(estimand != "Naive day level association")
activity_mix <- read_csv(here("data", "processed", "summary_activity_mix.csv"),
                         show_col_types = FALSE)
participant_metrics <- read_csv(here("data", "processed", "summary_participant_metrics.csv"),
                                show_col_types = FALSE)

p1 <- ggplot(coverage, aes(x = reorder(dataset, unique_users), y = unique_users, fill = dataset)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  coord_flip() +
  scale_fill_manual(values = setNames(
    unname(c(
      pal["teal"],
      pal["coral"],
      pal["gold"],
      pal["teal"],
      pal["slate"],
      pal["mist"]
    )),
    c(
      "daily_activity",
      "sleep_day",
      "weight_log",
      "hourly_steps",
      "hourly_intensities",
      "hourly_calories"
    )
  )) +
  labs(
    title = "Coverage drops outside core activity tracking.",
    subtitle = "Daily and hourly activity data cover 33 users, but sleep and weight logging are less complete.",
    x = NULL, y = "Unique users",
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p1, "01_dataset_coverage.png")

p2 <- ggplot(engagement, aes(x = engagement_segment, y = users, fill = engagement_segment)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_text(aes(label = users), vjust = -0.4, size = 4) +
  scale_fill_manual(values = unname(c(pal["coral"], pal["gold"], pal["teal"]))) +
  labs(
    title = "Most users log activity consistently across the month.",
    subtitle = "29 of 33 users recorded activity on at least 25 days, but that consistency does not extend to all wellness behaviors.",
    x = NULL, y = "Users",
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p2, "02_engagement_segments.png")

p3 <- ggplot(weekday, aes(day_of_week, avg_steps, group = 1)) +
  geom_errorbar(aes(ymin = ci_low, ymax = ci_high), width = 0.16, color = pal["mist"]) +
  geom_line(linewidth = 1.2, color = pal["teal"]) +
  geom_point(size = 2.5, color = pal["coral"]) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Weekly activity differences are visible but uncertain.",
    subtitle = "Participant weighted means with 95% participant bootstrap intervals",
    x = NULL, y = "Average steps",
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p3, "03_weekday_steps.png")

p4 <- ggplot(hourly, aes(hour_of_day, avg_steps)) +
  geom_ribbon(
    aes(ymin = ci_low, ymax = ci_high),
    fill = pal["mist"],
    alpha = 0.55
  ) +
  geom_line(linewidth = 1.2, color = pal["teal"]) +
  geom_point(size = 1.8, color = pal["gold"]) +
  scale_x_continuous(breaks = seq(0, 23, 2)) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Daytime and evening activity peaks remain uncertain.",
    subtitle = "Participant weighted means with 95% participant bootstrap intervals",
    x = "Hour of day", y = "Average steps",
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p4, "04_hourly_steps.png")

p5 <- ggplot(
  sleep_association,
  aes(x = estimate_hours_per_1000_steps, y = reorder(estimand, estimate_hours_per_1000_steps))
) +
  geom_vline(xintercept = 0, color = pal["mist"], linewidth = 1) +
  geom_errorbar(
    aes(xmin = ci_low, xmax = ci_high),
    orientation = "y",
    width = 0.16,
    color = pal["slate"]
  ) +
  geom_point(size = 3.2, color = pal["coral"]) +
  scale_x_continuous(labels = label_number(accuracy = 0.01)) +
  labs(
    title = "The activity and sleep relationship is uncertain.",
    subtitle = "Estimated sleep hours per 1,000 additional steps with 95% intervals",
    x = "Change in sleep hours", y = NULL,
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p5, "05_sleep_by_steps.png")

p6 <- ggplot(activity_mix, aes(activity_type, avg_minutes, fill = activity_type)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = round(avg_minutes)), vjust = -0.4, size = 4) +
  scale_fill_manual(values = unname(c(pal["slate"], pal["mist"], pal["gold"], pal["coral"]))) +
  labs(
    title = "Sedentary time dominates the average day.",
    subtitle = "Average minutes per day by activity intensity",
    x = NULL, y = "Average minutes",
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p6, "06_activity_mix.png")

p7_data <- participant_metrics |>
  filter(metric %in% c("Average daily steps", "Average sedentary hours")) |>
  mutate(
    display_metric = recode(
      metric,
      "Average daily steps" = "Daily steps",
      "Average sedentary hours" = "Sedentary hours"
    )
  )

p7 <- ggplot(p7_data, aes(estimate, 1)) +
  geom_errorbar(
    aes(xmin = ci_low, xmax = ci_high),
    orientation = "y",
    width = 0.18,
    color = pal["slate"]
  ) +
  geom_point(size = 3.2, color = pal["teal"]) +
  facet_wrap(~display_metric, scales = "free_x", ncol = 1) +
  scale_y_continuous(breaks = NULL) +
  labs(
    title = "Participant weighted behavior estimates remain imprecise.",
    subtitle = "Means and 95% participant bootstrap intervals",
    x = "Estimate", y = NULL,
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p7, "07_participant_uncertainty.png")

message("Saved seven figures to output/figures/")
