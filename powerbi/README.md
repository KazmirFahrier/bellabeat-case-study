# Power BI dashboard package

This folder is a complete, reviewable Power BI build package. It contains nine model ready CSV files, a report theme, reusable DAX measures, a three page layout specification, and an interactive browser prototype.

No `.pbix` binary is committed because Power BI Desktop is not available in this execution environment. A binary that could not be opened and tested would weaken reproducibility. The supplied assets let a reviewer rebuild the report in Power BI Desktop without reverse engineering the analysis.

## Build in Power BI Desktop

1. Run `Rscript R/run_all.R` from the repository root.
2. Open Power BI Desktop and choose Get data, then Text or CSV.
3. Import every CSV in `powerbi/data/` using the table name without the file extension.
4. Apply `theme.json` from View, Themes, Browse for themes.
5. Create the measures from `measures.dax`.
6. Build the three pages in `DASHBOARD_SPEC.md`.
7. Confirm that Quality Gate Status returns PASS before publishing.

All report tables are aggregates. The design intentionally avoids exposing raw participant day records.
