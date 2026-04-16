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
weekday <- read_csv(here("data", "processed", "summary_weekday_usage.csv"),
                    show_col_types = FALSE) |>
  mutate(
    day_of_week = factor(
      day_of_week,
      levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
    )
  )
hourly <- read_csv(here("data", "processed", "summary_hourly_usage.csv"),
                   show_col_types = FALSE)
sleep_steps <- read_csv(here("data", "processed", "summary_sleep_by_steps.csv"),
                        show_col_types = FALSE)
activity_mix <- read_csv(here("data", "processed", "summary_activity_mix.csv"),
                         show_col_types = FALSE)
segment <- read_csv(here("data", "processed", "summary_by_segment.csv"),
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
  geom_line(linewidth = 1.2, color = pal["teal"]) +
  geom_point(size = 2.5, color = pal["coral"]) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Daily movement follows a repeatable weekly rhythm.",
    subtitle = "Average daily steps by weekday",
    x = NULL, y = "Average steps",
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p3, "03_weekday_steps.png")

p4 <- ggplot(hourly, aes(hour_of_day, avg_steps)) +
  geom_line(linewidth = 1.2, color = pal["teal"]) +
  geom_point(size = 1.8, color = pal["gold"]) +
  scale_x_continuous(breaks = seq(0, 23, 2)) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Usage peaks cluster in daytime and early evening.",
    subtitle = "Average steps by hour of day",
    x = "Hour of day", y = "Average steps",
    caption = caption_txt
  ) +
  theme_bellabeat()

save_fig(p4, "04_hourly_steps.png")

p5 <- ggplot(sleep_steps, aes(step_bucket, avg_sleep_hours, fill = step_bucket)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = round(avg_sleep_hours, 1)), vjust = -0.4, size = 4) +
  scale_fill_manual(values = unname(c(pal["mist"], pal["gold"], pal["coral"], pal["teal"]))) +
  labs(
    title = "More movement does not automatically translate into more sleep.",
    subtitle = "Average sleep hours are lowest on 10k+ step days among users who logged sleep.",
    x = NULL, y = "Average sleep hours",
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

message("Saved ", length(list.files(fig_dir)), " figures to output/figures/")
