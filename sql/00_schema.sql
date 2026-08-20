-- Load the verified source files and create conformed dimensions.

CREATE OR REPLACE TABLE stg_daily_activity AS
SELECT *
FROM read_csv_auto('data/raw/dailyActivity_merged.csv', header = true);

CREATE OR REPLACE TABLE stg_sleep_day AS
SELECT *
FROM read_csv_auto('data/raw/sleepDay_merged.csv', header = true);

CREATE OR REPLACE TABLE stg_hourly_steps AS
SELECT *
FROM read_csv_auto('data/raw/hourlySteps_merged.csv', header = true);

CREATE OR REPLACE TABLE stg_hourly_intensities AS
SELECT *
FROM read_csv_auto('data/raw/hourlyIntensities_merged.csv', header = true);

CREATE OR REPLACE TABLE stg_hourly_calories AS
SELECT *
FROM read_csv_auto('data/raw/hourlyCalories_merged.csv', header = true);

CREATE OR REPLACE TABLE stg_weight_log AS
SELECT *
FROM read_csv_auto('data/raw/weightLogInfo_merged.csv', header = true);

CREATE OR REPLACE TABLE dim_participant AS
SELECT DISTINCT CAST(Id AS VARCHAR) AS participant_id
FROM (
    SELECT Id FROM stg_daily_activity
    UNION ALL
    SELECT Id FROM stg_sleep_day
    UNION ALL
    SELECT Id FROM stg_weight_log
)
ORDER BY participant_id;

CREATE OR REPLACE TABLE dim_date AS
WITH date_bounds AS (
    SELECT
        MIN(TRY_CAST(ActivityDate AS DATE)) AS start_date,
        MAX(TRY_CAST(ActivityDate AS DATE)) AS end_date
    FROM stg_daily_activity
)
SELECT
    calendar_date,
    dayname(calendar_date) AS day_name,
    isodow(calendar_date) AS iso_day_number,
    CASE WHEN isodow(calendar_date) IN (6, 7) THEN true ELSE false END AS is_weekend
FROM date_bounds,
LATERAL generate_series(start_date, end_date, INTERVAL 1 DAY) AS dates(calendar_date)
ORDER BY calendar_date;

CREATE OR REPLACE TABLE dim_hour AS
SELECT
    hour_of_day,
    CASE
        WHEN hour_of_day < 6 THEN 'Overnight'
        WHEN hour_of_day < 12 THEN 'Morning'
        WHEN hour_of_day < 17 THEN 'Afternoon'
        WHEN hour_of_day < 21 THEN 'Evening'
        ELSE 'Night'
    END AS daypart
FROM generate_series(0, 23) AS hours(hour_of_day);
