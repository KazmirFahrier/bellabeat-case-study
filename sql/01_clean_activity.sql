-- Apply typed business rules at the participant day grain.

CREATE OR REPLACE TABLE fact_daily_activity AS
WITH typed AS (
    SELECT
        CAST(Id AS VARCHAR) AS participant_id,
        TRY_CAST(ActivityDate AS DATE) AS activity_date,
        CAST(TotalSteps AS DOUBLE) AS total_steps,
        CAST(TotalDistance AS DOUBLE) AS total_distance,
        CAST(Calories AS DOUBLE) AS calories,
        CAST(SedentaryMinutes AS DOUBLE) AS sedentary_minutes,
        CAST(LightlyActiveMinutes AS DOUBLE) AS lightly_active_minutes,
        CAST(FairlyActiveMinutes AS DOUBLE) AS fairly_active_minutes,
        CAST(VeryActiveMinutes AS DOUBLE) AS very_active_minutes,
        ROW_NUMBER() OVER (
            PARTITION BY CAST(Id AS VARCHAR), TRY_CAST(ActivityDate AS DATE)
            ORDER BY Calories DESC, TotalSteps DESC
        ) AS duplicate_rank
    FROM stg_daily_activity
), valid_rows AS (
    SELECT *
    FROM typed
    WHERE duplicate_rank = 1
      AND activity_date IS NOT NULL
      AND total_steps >= 0
      AND calories > 0
)
SELECT
    participant_id,
    activity_date,
    total_steps,
    total_distance,
    calories,
    sedentary_minutes,
    lightly_active_minutes,
    fairly_active_minutes,
    very_active_minutes,
    lightly_active_minutes + fairly_active_minutes + very_active_minutes AS active_minutes,
    sedentary_minutes / 60.0 AS sedentary_hours,
    total_steps >= 10000 AS step_goal_achieved,
    CASE
        WHEN total_steps < 5000 THEN 'Under 5k'
        WHEN total_steps < 7500 THEN '5k-7.4k'
        WHEN total_steps < 10000 THEN '7.5k-9.9k'
        ELSE '10k+'
    END AS step_bucket
FROM valid_rows
ORDER BY participant_id, activity_date;
