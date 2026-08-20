-- Publish business definitions and analyst facing dashboard views.

CREATE OR REPLACE VIEW vw_business_rules AS
SELECT * FROM (VALUES
    ('participant_weighted_steps', 'Mean of each participant mean daily steps', 'participant_id', 'Equal participant weight'),
    ('sedentary_hours', 'Sedentary minutes divided by 60', 'participant_id, activity_date', 'Calories must be greater than zero'),
    ('step_goal_rate', 'Share of valid participant days with at least 10,000 steps', 'participant_id', '10,000 is a reporting threshold, not a clinical target'),
    ('sleep_log_rate', 'Matched sleep days divided by valid activity days', 'participant_id', 'Missing sleep is not labeled disengagement'),
    ('engagement_segment', 'Low: 1 to 10 days; Moderate: 11 to 24; High: 25 or more', 'participant_id', 'Descriptive segmentation only')
) AS rules(metric_name, definition, grain, quality_rule);

CREATE OR REPLACE VIEW vw_dashboard_participant_summary AS
SELECT
    participant_id,
    activity_days,
    avg_steps,
    avg_active_minutes,
    avg_sedentary_hours,
    step_goal_rate,
    sleep_log_rate,
    weight_log_rate,
    engagement_segment
FROM participant_kpis;

CREATE OR REPLACE VIEW vw_dashboard_quality AS
SELECT check_name, actual_value, expected_value, passed, business_rule
FROM vw_quality_checks;
