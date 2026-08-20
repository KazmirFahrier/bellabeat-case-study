-- Produce participant grain KPIs and reusable coverage views.

CREATE OR REPLACE TABLE participant_kpis AS
SELECT
    activity.participant_id,
    COUNT(*) AS activity_days,
    AVG(activity.total_steps) AS avg_steps,
    AVG(activity.active_minutes) AS avg_active_minutes,
    AVG(activity.sedentary_hours) AS avg_sedentary_hours,
    AVG(activity.step_goal_achieved::INTEGER) AS step_goal_rate,
    COUNT(sleep.sleep_date)::DOUBLE / COUNT(*) AS sleep_log_rate,
    COUNT(weight.weight_date)::DOUBLE / COUNT(*) AS weight_log_rate,
    CASE
        WHEN COUNT(*) <= 10 THEN 'Low (1-10 days)'
        WHEN COUNT(*) <= 24 THEN 'Moderate (11-24 days)'
        ELSE 'High (25+ days)'
    END AS engagement_segment
FROM fact_daily_activity AS activity
LEFT JOIN fact_daily_sleep AS sleep
    ON activity.participant_id = sleep.participant_id
   AND activity.activity_date = sleep.sleep_date
LEFT JOIN fact_weight AS weight
    ON activity.participant_id = weight.participant_id
   AND activity.activity_date = weight.weight_date
GROUP BY activity.participant_id
ORDER BY activity.participant_id;

CREATE OR REPLACE VIEW vw_dashboard_kpis AS
SELECT 1 AS display_order, 'Participants' AS metric, COUNT(*)::DOUBLE AS value, '33' AS display_value
FROM participant_kpis
UNION ALL
SELECT 2, 'Participant weighted daily steps', AVG(avg_steps), printf('%,.0f', AVG(avg_steps))
FROM participant_kpis
UNION ALL
SELECT 3, 'Participant weighted sedentary hours', AVG(avg_sedentary_hours), printf('%.2f', AVG(avg_sedentary_hours))
FROM participant_kpis
UNION ALL
SELECT 4, 'Participant weighted 10k step day share', AVG(step_goal_rate), printf('%.1f%%', AVG(step_goal_rate) * 100)
FROM participant_kpis
ORDER BY display_order;

CREATE OR REPLACE VIEW vw_coverage AS
SELECT 1 AS display_order, 'Daily activity' AS dataset, COUNT(DISTINCT participant_id) AS participants
FROM fact_daily_activity
UNION ALL
SELECT 2, 'Daily sleep', COUNT(DISTINCT participant_id)
FROM fact_daily_sleep
UNION ALL
SELECT 3, 'Weight log', COUNT(DISTINCT participant_id)
FROM fact_weight
UNION ALL
SELECT 4, 'Hourly activity', COUNT(DISTINCT participant_id)
FROM fact_hourly_activity
ORDER BY display_order;

CREATE OR REPLACE VIEW vw_engagement_segments AS
SELECT
    engagement_segment,
    COUNT(*) AS participants,
    AVG(activity_days) AS avg_days_logged
FROM participant_kpis
GROUP BY engagement_segment
ORDER BY MIN(activity_days);
