source(file.path("R", "run_all.R"))

read_summary <- function(name) {
  utils::read.csv(file.path("data", "processed", name), check.names = FALSE)
}

required_outputs <- c(
  "summary_data_quality.csv",
  "summary_participant_metrics.csv",
  "summary_weekday_participant.csv",
  "summary_hourly_participant.csv",
  "summary_sleep_association.csv",
  "summary_estimand_sensitivity.csv",
  "summary_missingness.csv",
  "product_experiments.csv"
)
stopifnot(all(file.exists(file.path("data", "processed", required_outputs))))

manifest <- utils::read.csv(file.path("data", "RAW_DATA_MANIFEST.csv"))
stopifnot(nrow(manifest) == 7)
stopifnot(
  manifest$sha256[manifest$file == "Fitabase archive"] ==
    "763e2c130202ee4ee5fd389dfa8faf447414d66011fa7e97cf8e6b77d1593ac7"
)

quality <- read_summary("summary_data_quality.csv")
quality_value <- function(check) as.character(quality$value[quality$check == check])
stopifnot(quality_value("daily_rows") == "936")
stopifnot(quality_value("daily_source_rows") == "940")
stopifnot(quality_value("daily_rows_excluded") == "4")
stopifnot(quality_value("daily_users") == "33")
stopifnot(quality_value("sleep_source_rows") == "413")
stopifnot(quality_value("sleep_rows_consolidated") == "3")
stopifnot(quality_value("sleep_users") == "24")
stopifnot(quality_value("weight_users") == "8")
stopifnot(quality_value("hourly_rows") == "22099")

participant <- read_summary("summary_participant_metrics.csv")
steps <- participant[participant$metric == "Average daily steps", ]
stopifnot(abs(steps$estimate - 7555.81) < 0.1)
stopifnot(steps$ci_low < steps$estimate, steps$estimate < steps$ci_high)
stopifnot(steps$participants == 33)

weekday <- read_summary("summary_weekday_participant.csv")
hourly <- read_summary("summary_hourly_participant.csv")
stopifnot(nrow(weekday) == 7, nrow(hourly) == 24)
stopifnot(all(is.finite(weekday$ci_low)), all(is.finite(hourly$ci_low)))
stopifnot(weekday$day_of_week[which.max(weekday$avg_steps)] == "Saturday")
stopifnot(hourly$hour_of_day[which.max(hourly$avg_steps)] == 18)

sleep <- read_summary("summary_sleep_association.csv")
within <- sleep[sleep$estimand == "Within participant association", ]
naive <- sleep[sleep$estimand == "Naive day level association", ]
stopifnot(within$participants == 18, within$observations == 394)
stopifnot(within$ci_low < 0, within$ci_high > 0)
stopifnot(naive$ci_high < 0)

experiments <- read_summary("product_experiments.csv")
stopifnot(nrow(experiments) == 3)
stopifnot(all(nzchar(experiments$primary_metric)), all(nzchar(experiments$guardrail)))

figures <- list.files(file.path("output", "figures"), pattern = "[.]png$", full.names = TRUE)
stopifnot(length(figures) == 7)
stopifnot(all(file.info(figures)$size > 20000))

message("All pipeline and scientific checks passed.")
