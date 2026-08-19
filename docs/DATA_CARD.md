# Fitabase Data Card

## Purpose

This repository uses public Fitbit records for an educational, retrospective behavioral analysis.
It does not contain Bellabeat customer data and should not be used for individual health decisions,
employee monitoring, clinical inference, or production personalization.

## Source snapshot

| Field | Value |
| --- | --- |
| Dataset | Fitabase Data 4.12.16 to 5.12.16 |
| Observed period | April 12 through May 12, 2016 |
| Programmatic source | Pinned third party GitHub mirror |
| Source commit | `2faf8db5f798d79b4400dd07f73c3116e53ff01d` |
| Archive SHA 256 | `763e2c130202ee4ee5fd389dfa8faf447414d66011fa7e97cf8e6b77d1593ac7` |
| Raw data in Git | No |

The exact URL and selected file digests are recorded in
[`../data/RAW_DATA_MANIFEST.csv`](../data/RAW_DATA_MANIFEST.csv). The pipeline rejects cached or
downloaded files whose digests do not match the manifest.

## Files used

1. `dailyActivity_merged.csv`
2. `sleepDay_merged.csv`
3. `hourlySteps_merged.csv`
4. `hourlyIntensities_merged.csv`
5. `hourlyCalories_merged.csv`
6. `weightLogInfo_merged.csv`

## Coverage

Daily activity contains 936 records from 33 participants. Sleep covers 410 participant days and
24 participants. Weight covers 67 records and 8 participants. The primary sleep analysis further
requires five matched sleep days and therefore includes 18 participants and 394 days.

The source daily file contains 940 rows. Four zero calorie placeholder days are excluded. The
source sleep file contains 413 rows, and three duplicate participant days are consolidated.

## Known limitations

The available archive does not document a sampling frame, participant demographics, device model,
geography, health status, or recruitment process. Missing records may reflect nonwear, device
capability, setup, syncing, manual entry, or personal preference. Missingness must not be interpreted
as a diagnosis or a stable behavioral trait.

The dataset is widely described as CC0 through its Kaggle distribution. This repository does not
redistribute the raw files. Users who obtain the archive should independently confirm the current
source terms. The project MIT license covers authored code and documentation, not third party data.

## Responsible interpretation

Report participant counts alongside observation counts. Use participant aware intervals for
repeated measures. Avoid causal language. Treat any marketing or product idea as a hypothesis that
requires a prospective user level experiment and privacy review.
