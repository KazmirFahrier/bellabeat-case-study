# Data dictionary

## Dimensions

| Table | Field | Type | Definition | Null rule |
|---|---|---|---|---|
| `dim_participant` | `participant_id` | text | Anonymous source identifier | Never null |
| `dim_date` | `calendar_date` | date | Calendar date from April 12 to May 12, 2016 | Never null |
| `dim_date` | `day_name` | text | Full weekday name | Never null |
| `dim_date` | `iso_day_number` | integer | Monday equals 1 and Sunday equals 7 | Never null |
| `dim_date` | `is_weekend` | boolean | True for Saturday or Sunday | Never null |
| `dim_hour` | `hour_of_day` | integer | Hour from 0 through 23 | Never null |
| `dim_hour` | `daypart` | text | Overnight, Morning, Afternoon, Evening, or Night | Never null |

## Daily activity fact

| Field | Type | Definition | Null rule |
|---|---|---|---|
| `participant_id` | text | Anonymous participant key | Never null |
| `activity_date` | date | Date of the activity record | Never null |
| `total_steps` | number | Total recorded steps | Nonnegative |
| `total_distance` | number | Total distance reported by the source | Nonnegative |
| `calories` | number | Daily calorie estimate | Greater than zero after quality filtering |
| `sedentary_minutes` | number | Recorded sedentary minutes | Nonnegative |
| `lightly_active_minutes` | number | Recorded lightly active minutes | Nonnegative |
| `fairly_active_minutes` | number | Recorded fairly active minutes | Nonnegative |
| `very_active_minutes` | number | Recorded very active minutes | Nonnegative |
| `active_minutes` | number | Sum of the three active minute fields | Derived, nonnegative |
| `sedentary_hours` | number | Sedentary minutes divided by 60 | Derived, nonnegative |
| `step_goal_achieved` | boolean | True when total steps are at least 10,000 | Never null |
| `step_bucket` | text | Under 5k, 5k to 7.4k, 7.5k to 9.9k, or 10k plus | Never null |

## Sleep and weight facts

| Table | Field | Type | Definition | Null rule |
|---|---|---|---|---|
| `fact_daily_sleep` | `sleep_date` | date | Consolidated sleep day | Never null |
| `fact_daily_sleep` | `total_sleep_records` | number | Average source record count within a duplicated participant day | Never null |
| `fact_daily_sleep` | `total_minutes_asleep` | number | Logged minutes asleep | Never null |
| `fact_daily_sleep` | `total_time_in_bed` | number | Logged minutes in bed | Never null |
| `fact_weight` | `weight_date` | date | Date of the weight record | Never null |
| `fact_weight` | `weight_kg` | number | Weight in kilograms | Never null |
| `fact_weight` | `bmi` | number | Source body mass index | Never null |

Both facts also contain `participant_id`. Sleep duplicate participant days are consolidated. Weight remains sparse and is not used for recommendation claims.

## Hourly activity fact

| Field | Type | Definition | Null rule |
|---|---|---|---|
| `participant_id` | text | Anonymous participant key | Never null |
| `activity_hour` | timestamp | Start of the recorded hour | Never null |
| `hour_of_day` | integer | Hour from 0 through 23 | Never null |
| `step_total` | number | Steps recorded in the hour | Nonnegative |
| `total_intensity` | number | Total source intensity | Nonnegative |
| `average_intensity` | number | Average source intensity | Nonnegative |
| `calories` | number | Hourly calorie estimate | Nonnegative |

## Participant KPI table

| Field | Type | Definition |
|---|---|---|
| `activity_days` | integer | Valid activity days for the participant |
| `avg_steps` | number | Mean daily steps for the participant |
| `avg_active_minutes` | number | Mean active minutes for the participant |
| `avg_sedentary_hours` | number | Mean sedentary hours for the participant |
| `step_goal_rate` | percentage | Share of participant days with at least 10,000 steps |
| `sleep_log_rate` | percentage | Share of activity days joined to a sleep record |
| `weight_log_rate` | percentage | Share of activity days joined to a weight record |
| `engagement_segment` | text | Low for 1 to 10 days, Moderate for 11 to 24, High for at least 25 |

## Reporting outputs

| File | Grain | Use |
|---|---|---|
| `executive_kpis.csv` | One row per metric | Executive cards |
| `weekday_activity.csv` | One row per weekday | Usage pattern visual with confidence intervals |
| `hourly_activity.csv` | One row per hour | Hourly usage visual with confidence intervals |
| `coverage.csv` | One row per dataset | Source coverage disclosure |
| `engagement_segments.csv` | One row per segment | Engagement distribution |
| `evidence.csv` | One row per sleep estimand | Association evidence and uncertainty |
| `sensitivity.csv` | One row per metric | Participant versus observation weighting |
| `data_quality.csv` | One row per SQL check | Executable data quality gate |
