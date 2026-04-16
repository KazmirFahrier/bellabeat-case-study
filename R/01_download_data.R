# =============================================================================
# 01_download_data.R
# Bellabeat Case Study — Download Fitabase archive and extract selected files
# =============================================================================

library(here)

dir.create(here("data", "raw"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("data", "processed"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("output", "figures"), showWarnings = FALSE, recursive = TRUE)

fitabase_url <- paste0(
  "https://raw.githubusercontent.com/",
  "sayantanbagchi/Bellabeat-Case-Study/main/",
  "FitBit%20Dataset/Fitabase%20Data%204.12.16-5.12.16.zip"
)

zip_path <- here("data", "raw", "fitabase_data.zip")

selected_files <- c(
  "dailyActivity_merged.csv",
  "sleepDay_merged.csv",
  "hourlySteps_merged.csv",
  "hourlyIntensities_merged.csv",
  "hourlyCalories_merged.csv",
  "weightLogInfo_merged.csv"
)

selected_members <- file.path("Fitabase Data 4.12.16-5.12.16", selected_files)
selected_paths <- here("data", "raw", selected_files)

if (all(file.exists(selected_paths))) {
  message("Selected Fitabase CSVs already exist in data/raw/ — skipping download.")
} else {
  message("Downloading Fitabase archive ...")
  download.file(fitabase_url, destfile = zip_path, mode = "wb")

  message("Extracting selected files ...")
  unzip(zip_path, files = selected_members, exdir = here("data", "raw"), junkpaths = TRUE)
  file.remove(zip_path)
}

message("Done. Selected files available in data/raw/")
