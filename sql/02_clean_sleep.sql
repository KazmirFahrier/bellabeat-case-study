-- Consolidate sleep and weight records and join the hourly source tables.

CREATE OR REPLACE TABLE fact_daily_sleep AS
WITH typed AS (
    SELECT
        CAST(Id AS VARCHAR) AS participant_id,
        TRY_CAST(SleepDay AS DATE) AS sleep_date,
        CAST(TotalSleepRecords AS DOUBLE) AS total_sleep_records,
        CAST(TotalMinutesAsleep AS DOUBLE) AS total_minutes_asleep,
        CAST(TotalTimeInBed AS DOUBLE) AS total_time_in_bed
    FROM stg_sleep_day
)
SELECT
    participant_id,
    sleep_date,
    AVG(total_sleep_records) AS total_sleep_records,
    AVG(total_minutes_asleep) AS total_minutes_asleep,
    AVG(total_time_in_bed) AS total_time_in_bed
FROM typed
WHERE sleep_date IS NOT NULL
GROUP BY participant_id, sleep_date
ORDER BY participant_id, sleep_date;

CREATE OR REPLACE TABLE fact_weight AS
WITH typed AS (
    SELECT
        CAST(Id AS VARCHAR) AS participant_id,
        TRY_CAST(Date AS DATE) AS weight_date,
        CAST(WeightKg AS DOUBLE) AS weight_kg,
        CAST(BMI AS DOUBLE) AS bmi
    FROM stg_weight_log
)
SELECT
    participant_id,
    weight_date,
    AVG(weight_kg) AS weight_kg,
    AVG(bmi) AS bmi
FROM typed
WHERE weight_date IS NOT NULL
GROUP BY participant_id, weight_date
ORDER BY participant_id, weight_date;

CREATE OR REPLACE TABLE fact_hourly_activity AS
WITH steps AS (
    SELECT
        CAST(Id AS VARCHAR) AS participant_id,
        TRY_CAST(ActivityHour AS TIMESTAMP) AS activity_hour,
        CAST(StepTotal AS DOUBLE) AS step_total
    FROM stg_hourly_steps
), intensities AS (
    SELECT
        CAST(Id AS VARCHAR) AS participant_id,
        TRY_CAST(ActivityHour AS TIMESTAMP) AS activity_hour,
        CAST(TotalIntensity AS DOUBLE) AS total_intensity,
        CAST(AverageIntensity AS DOUBLE) AS average_intensity
    FROM stg_hourly_intensities
), calories AS (
    SELECT
        CAST(Id AS VARCHAR) AS participant_id,
        TRY_CAST(ActivityHour AS TIMESTAMP) AS activity_hour,
        CAST(Calories AS DOUBLE) AS calories
    FROM stg_hourly_calories
)
SELECT
    steps.participant_id,
    steps.activity_hour,
    EXTRACT('hour' FROM steps.activity_hour)::INTEGER AS hour_of_day,
    steps.step_total,
    intensities.total_intensity,
    intensities.average_intensity,
    calories.calories
FROM steps
INNER JOIN intensities USING (participant_id, activity_hour)
INNER JOIN calories USING (participant_id, activity_hour)
ORDER BY participant_id, activity_hour;
