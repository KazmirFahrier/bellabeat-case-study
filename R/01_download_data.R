# =============================================================================
# 01_download_data.R
# Bellabeat Case Study: download and verify the Fitabase archive
# =============================================================================

library(digest)
library(here)

dir.create(here("data", "raw"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("data", "processed"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("output", "figures"), showWarnings = FALSE, recursive = TRUE)

source_commit <- "2faf8db5f798d79b4400dd07f73c3116e53ff01d"
fitabase_url <- paste0(
  "https://raw.githubusercontent.com/",
  "sayantanbagchi/Bellabeat-Case-Study/",
  source_commit,
  "/",
  "FitBit%20Dataset/Fitabase%20Data%204.12.16-5.12.16.zip"
)

expected_archive_sha256 <- "763e2c130202ee4ee5fd389dfa8faf447414d66011fa7e97cf8e6b77d1593ac7"

zip_path <- here("data", "raw", "fitabase_data.zip")

selected_files <- c(
  "dailyActivity_merged.csv",
  "sleepDay_merged.csv",
  "hourlySteps_merged.csv",
  "hourlyIntensities_merged.csv",
  "hourlyCalories_merged.csv",
  "weightLogInfo_merged.csv"
)

expected_file_sha256 <- c(
  dailyActivity_merged.csv = "4b8f557eb29cd929cee7cc2d2a5e7704578bbffbc42c352e7b0c42bc4f3c6ac8",
  sleepDay_merged.csv = "2d4250ca47dfc74263f1b61fe4ba3e338c83faab0d352fb0fefa93464b170e53",
  hourlySteps_merged.csv = "83b9c1acc782b58a75a550f2f1d4ee9da7723e0ec26798b502768420cf6d7316",
  hourlyIntensities_merged.csv = "a2cc7eccfb86e710931bcb34678910cbdc2bf4798b0e1c9c43f37f919871fece",
  hourlyCalories_merged.csv = "10297488228ac4bf9cb86e8aa640208fe02e4fc479f6af1261ce52d8ab7f6b22",
  weightLogInfo_merged.csv = "50b40176f926562e1a522dcb4e75f30c4f04441a7d5b8e570f704b1fbab2b738"
)

selected_members <- file.path("Fitabase Data 4.12.16-5.12.16", selected_files)
selected_paths <- here("data", "raw", selected_files)

if (all(file.exists(selected_paths))) {
  message("Selected Fitabase CSVs already exist in data/raw/ — skipping download.")
} else {
  message("Downloading Fitabase archive ...")
  download.file(fitabase_url, destfile = zip_path, mode = "wb")

  archive_sha256 <- digest(zip_path, algo = "sha256", file = TRUE, serialize = FALSE)
  if (!identical(archive_sha256, expected_archive_sha256)) {
    stop("Downloaded archive failed its SHA 256 integrity check.", call. = FALSE)
  }

  message("Extracting selected files ...")
  unzip(zip_path, files = selected_members, exdir = here("data", "raw"), junkpaths = TRUE)
  file.remove(zip_path)
}

actual_file_sha256 <- vapply(
  selected_paths,
  digest,
  character(1),
  algo = "sha256",
  file = TRUE,
  serialize = FALSE
)

if (!identical(unname(actual_file_sha256), unname(expected_file_sha256[selected_files]))) {
  failed <- selected_files[actual_file_sha256 != expected_file_sha256[selected_files]]
  stop(
    "Extracted files failed integrity checks: ",
    paste(failed, collapse = ", "),
    call. = FALSE
  )
}

manifest <- data.frame(
  file = c("Fitabase archive", selected_files),
  sha256 = c(expected_archive_sha256, unname(expected_file_sha256[selected_files])),
  source_commit = source_commit,
  source_url = fitabase_url,
  stringsAsFactors = FALSE
)
utils::write.csv(
  manifest,
  here("data", "RAW_DATA_MANIFEST.csv"),
  row.names = FALSE,
  quote = TRUE
)

message("Done. Source and selected files passed SHA 256 checks.")
