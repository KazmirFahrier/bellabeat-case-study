# Bellabeat Smart Device Case Study

**Google Data Analytics Capstone — How can a wellness technology company play it smart?**

This project analyzes public Fitbit usage data to identify smart-device usage
trends that Bellabeat can translate into product and marketing strategy.

The analysis is built as a reproducible R pipeline that downloads the original
Fitabase archive, cleans a focused set of activity, sleep, hourly, and weight
files, generates summary tables, and renders portfolio-ready visualizations.

See [`docs/REPORT.md`](docs/REPORT.md) for the full write-up.

---

## Repository Structure

```text
bellabeat-case-study/
├── R/
│   ├── 01_download_data.R
│   ├── 02_clean_and_merge.R
│   ├── 03_analyze.R
│   ├── 04_visualize.R
│   └── run_all.R
├── data/
│   ├── raw/
│   └── processed/
├── output/
│   └── figures/
├── docs/
│   └── REPORT.md
├── README.md
└── .gitignore
```

---

## How to Reproduce

**Requirements:** R >= 4.2, internet access, and about 500 MB of free disk
space.

```r
install.packages(c("tidyverse", "lubridate", "here", "janitor", "scales"))
source("R/run_all.R")
```

That command will:
1. Download the public Fitabase ZIP archive
2. Extract the CSVs used in the analysis
3. Clean and merge daily, sleep, hourly, and weight data
4. Generate summary tables in `data/processed/`
5. Render six charts in `output/figures/`

---

## Data Source

Primary source: public Fitabase archive mirrored in a public GitHub repository
that preserves the original `Fitabase Data 4.12.16-5.12.16.zip` file used for
the Bellabeat capstone dataset.

The underlying dataset is the Fitbit Fitness Tracker Data released under CC0
Public Domain through Kaggle / Mobius. It contains data from 33 users for
activity data, smaller subsets for sleep and weight logging, and reflects a
limited time window in 2016.

---

## Tools

- **R / tidyverse** — wrangling and analysis
- **lubridate** — date-time parsing
- **ggplot2** — charting
- **janitor / scales** — cleaning and formatting helpers

---

## License

MIT — see [`LICENSE`](LICENSE).
