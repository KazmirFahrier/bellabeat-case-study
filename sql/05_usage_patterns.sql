-- Use two stage aggregation so every participant receives equal weight.

CREATE OR REPLACE VIEW vw_weekday_usage AS
WITH participant_weekday AS (
    SELECT
        activity.participant_id,
        dates.day_name,
        dates.iso_day_number,
        AVG(activity.total_steps) AS avg_steps,
        AVG(activity.active_minutes) AS avg_active_minutes,
        AVG(activity.sedentary_hours) AS avg_sedentary_hours,
        AVG(activity.step_goal_achieved::INTEGER) AS step_goal_rate
    FROM fact_daily_activity AS activity
    INNER JOIN dim_date AS dates ON activity.activity_date = dates.calendar_date
    GROUP BY activity.participant_id, dates.day_name, dates.iso_day_number
)
SELECT
    day_name,
    iso_day_number,
    COUNT(*) AS participant_day_profiles,
    AVG(avg_steps) AS participant_weighted_steps,
    AVG(avg_active_minutes) AS participant_weighted_active_minutes,
    AVG(avg_sedentary_hours) AS participant_weighted_sedentary_hours,
    AVG(step_goal_rate) AS participant_weighted_goal_rate
FROM participant_weekday
GROUP BY day_name, iso_day_number
ORDER BY iso_day_number;

CREATE OR REPLACE VIEW vw_hourly_usage AS
WITH participant_hour AS (
    SELECT
        participant_id,
        hour_of_day,
        AVG(step_total) AS avg_steps,
        AVG(total_intensity) AS avg_intensity,
        AVG(calories) AS avg_calories
    FROM fact_hourly_activity
    GROUP BY participant_id, hour_of_day
)
SELECT
    participant_hour.hour_of_day,
    dim_hour.daypart,
    COUNT(*) AS participant_hour_profiles,
    AVG(participant_hour.avg_steps) AS participant_weighted_steps,
    AVG(participant_hour.avg_intensity) AS participant_weighted_intensity,
    AVG(participant_hour.avg_calories) AS participant_weighted_calories
FROM participant_hour
INNER JOIN dim_hour USING (hour_of_day)
GROUP BY participant_hour.hour_of_day, dim_hour.daypart
ORDER BY participant_hour.hour_of_day;

CREATE OR REPLACE VIEW vw_estimand_sensitivity AS
SELECT
    'Average daily steps' AS metric,
    (SELECT AVG(total_steps) FROM fact_daily_activity) AS observation_weighted,
    (SELECT AVG(avg_steps) FROM participant_kpis) AS participant_weighted
UNION ALL
SELECT
    'Average sedentary hours',
    (SELECT AVG(sedentary_hours) FROM fact_daily_activity),
    (SELECT AVG(avg_sedentary_hours) FROM participant_kpis)
UNION ALL
SELECT
    '10k step day share',
    (SELECT AVG(step_goal_achieved::INTEGER) FROM fact_daily_activity),
    (SELECT AVG(step_goal_rate) FROM participant_kpis);
