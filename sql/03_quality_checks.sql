-- Turn source expectations and business rules into executable quality checks.

CREATE OR REPLACE VIEW vw_quality_checks AS
WITH sleep_ranked AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY CAST(Id AS VARCHAR), TRY_CAST(SleepDay AS DATE)
            ORDER BY TotalMinutesAsleep DESC
        ) AS duplicate_rank
    FROM stg_sleep_day
), checks AS (
    SELECT 'daily_source_rows' AS check_name, COUNT(*)::BIGINT AS actual_value, 940::BIGINT AS expected_value,
           'Source snapshot row count' AS business_rule
    FROM stg_daily_activity
    UNION ALL
    SELECT 'daily_valid_rows', COUNT(*)::BIGINT, 936::BIGINT,
           'Exclude zero calorie placeholder days'
    FROM fact_daily_activity
    UNION ALL
    SELECT 'daily_participants', COUNT(DISTINCT participant_id)::BIGINT, 33::BIGINT,
           'Verified source participant count'
    FROM fact_daily_activity
    UNION ALL
    SELECT 'daily_duplicate_keys', (COUNT(*) - COUNT(DISTINCT (participant_id, activity_date)))::BIGINT, 0::BIGINT,
           'One row per participant and activity date'
    FROM fact_daily_activity
    UNION ALL
    SELECT 'sleep_source_rows', COUNT(*)::BIGINT, 413::BIGINT,
           'Source snapshot row count'
    FROM stg_sleep_day
    UNION ALL
    SELECT 'sleep_duplicate_rows', SUM(CASE WHEN duplicate_rank > 1 THEN 1 ELSE 0 END)::BIGINT, 3::BIGINT,
           'Duplicate participant days are consolidated'
    FROM sleep_ranked
    UNION ALL
    SELECT 'sleep_user_days', COUNT(*)::BIGINT, 410::BIGINT,
           'One row per participant and sleep date'
    FROM fact_daily_sleep
    UNION ALL
    SELECT 'sleep_participants', COUNT(DISTINCT participant_id)::BIGINT, 24::BIGINT,
           'Verified source participant count'
    FROM fact_daily_sleep
    UNION ALL
    SELECT 'weight_participants', COUNT(DISTINCT participant_id)::BIGINT, 8::BIGINT,
           'Sparse weight coverage is retained as a limitation'
    FROM fact_weight
    UNION ALL
    SELECT 'weight_user_days', COUNT(*)::BIGINT, 67::BIGINT,
           'Verified weight record count after daily consolidation'
    FROM fact_weight
    UNION ALL
    SELECT 'hourly_join_rows', COUNT(*)::BIGINT, 22099::BIGINT,
           'Hourly joins must preserve the verified row count'
    FROM fact_hourly_activity
    UNION ALL
    SELECT 'hourly_null_keys', COUNT(*)::BIGINT, 0::BIGINT,
           'Hourly participant and timestamp keys cannot be null'
    FROM fact_hourly_activity
    WHERE participant_id IS NULL OR activity_hour IS NULL
)
SELECT
    check_name,
    actual_value,
    expected_value,
    actual_value = expected_value AS passed,
    business_rule
FROM checks
ORDER BY check_name;
