# =============================================================================
# run_all.R: orchestrate the Bellabeat pipeline
# =============================================================================

library(here)

source(here("R", "00_utils.R"))
source(here("R", "01_download_data.R"))

python_candidates <- c(
  Sys.getenv("BELLABEAT_PYTHON", unset = ""),
  here(".venv", "bin", "python"),
  Sys.which("python"),
  Sys.which("python3")
)
python_candidates <- python_candidates[nzchar(python_candidates) & file.exists(python_candidates)]
if (length(python_candidates) == 0) {
  stop("Python with DuckDB is required. Install requirements.txt first.", call. = FALSE)
}
python_executable <- python_candidates[[1]]

sql_status <- system2(
  python_executable,
  here("scripts", "run_sql.py"),
  stdout = "",
  stderr = ""
)
if (!identical(sql_status, 0L)) {
  stop("DuckDB warehouse build failed.", call. = FALSE)
}

source(here("R", "02_clean_and_merge.R"))
source(here("R", "03_analyze.R"))
source(here("R", "04_inference.R"))
source(here("R", "04_visualize.R"))
source(here("R", "05_powerbi_exports.R"))

for (script_name in c("build_dashboard.py", "generate_executive_brief.py")) {
  script_status <- system2(
    python_executable,
    here("scripts", script_name),
    stdout = "",
    stderr = ""
  )
  if (!identical(script_status, 0L)) {
    stop(paste("Failed to run", script_name), call. = FALSE)
  }
}

message(
  "\nPipeline complete. See output/figures/ for charts and ",
  "data/processed/ for summary CSVs and powerbi/ for dashboard assets."
)
