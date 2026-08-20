# Bellabeat Usage Intelligence: Participant Aware Evidence Report

**Author:** Kazmir Fahrier<br>
**Project type:** Portfolio product analytics project<br>
**Tools:** DuckDB SQL, R, tidyverse, ggplot2, Power BI, participant bootstrap, fixed effects<br>
**Study period:** April 12 through May 12, 2016

## Executive summary

This study evaluates public Fitbit usage data as a source of product hypotheses for a wellness
technology company. It deliberately avoids treating repeated daily records as independent users.
The principal results are participant weighted summaries, participant bootstrap intervals, and a
within participant activity and sleep analysis. DuckDB provides the typed analytical layer and
executable quality gates. Power BI ready tables provide a separate decision reporting layer.

The dataset supports descriptions of this sample, not claims about Bellabeat customers. The
participant weighted average is 7,556 daily steps with a 95% participant bootstrap interval from
6,413 to 8,718. Average sedentary time is 16.63 hours, with an interval from 15.38 to 17.86.

The most important correction concerns sleep. A naive regression of 394 matched days estimates
minus 0.085 sleep hours per additional 1,000 steps and produces an interval entirely below zero.
A participant fixed effects model estimates minus 0.058 hours, but its participant bootstrap
interval runs from minus 0.127 to 0.015. Once participant dependence is respected, the data does
not establish a reliable activity and sleep association.

## 1. Business question

Which observed smart device usage patterns are strong enough to motivate Bellabeat product and
marketing experiments, and which apparent findings disappear under a participant aware analysis?

The decision standard is intentionally conservative:

1. Observed patterns may suggest a hypothesis.
2. Wide uncertainty lowers the evidence grade.
3. Product impact requires a prospective experiment.
4. Historical Fitbit users are not assumed to represent Bellabeat customers.

## 2. Data and provenance

The analysis uses six files from the public Fitabase archive: daily activity, daily sleep, three
hourly measures, and weight logs. The pipeline pins the third party mirror to Git commit
`2faf8db5f798d79b4400dd07f73c3116e53ff01d` and verifies the archive with SHA 256 digest
`763e2c130202ee4ee5fd389dfa8faf447414d66011fa7e97cf8e6b77d1593ac7`.

The source daily file contains 940 rows. Four rows with zero reported calories are excluded as
invalid device day placeholders, leaving 936 analysis rows. Three duplicate sleep day records are
consolidated to one participant day, leaving 410 matched sleep days.

| Coverage item | Count |
| --- | ---: |
| Daily activity observations | 936 |
| Activity participants | 33 |
| Matched sleep days | 410 |
| Participants with any sleep record | 24 |
| Weight records | 67 |
| Participants with any weight record | 8 |
| Matched hourly observations | 22,099 |

Weight data is too sparse for a behavioral conclusion and is retained only for a coverage audit.
The source and responsible use details are documented in [`DATA_CARD.md`](DATA_CARD.md).

![Dataset coverage](../output/figures/01_dataset_coverage.png)

## 3. Analytical design

### Unit of evidence

Each participant contributes one mean to participant weighted summaries. A person with 31 logged
days therefore does not automatically receive more influence than a person with 20 logged days.

### Uncertainty

Two thousand bootstrap samples resample participants with replacement. The resulting percentile
intervals reflect variation across the observed participants. They do not cover recruitment bias,
measurement error, or the age of the data.

### Activity and sleep estimands

Three models expose how the question changes:

1. The naive day level model treats matched days as independent.
2. The within participant model adds participant fixed effects and asks whether a person's
   higher step days differ from that same person's usual sleep.
3. The between participant model compares participant level means.

Only 18 participants have at least five matched sleep days, leaving 394 observations in these
models. The within participant model is the primary analysis because it removes stable differences
between participants, though time varying confounding remains.

## 4. Findings

### Finding 1: activity tracking is broad, but cross domain coverage is selective

All 33 participants have activity records. Sleep records appear for 24 participants, while weight
records appear for only 8. The participant weighted share of days with a sleep record is 41.8%,
with a wide interval from 29.0% to 56.4%.

This is evidence about data availability, not motivation. Missing sleep and weight records may
reflect device capability, setup, adherence, manual entry, or user preference. A product team
should not label absent records as disengagement without first party instrumentation.

**Evidence grade:** moderate for coverage, low for behavioral explanation.

![Engagement segments](../output/figures/02_engagement_segments.png)

### Finding 2: routine windows are visible, but ranks are not precise

Participant weighted activity is highest on Saturday at about 8,400 steps and lowest on Sunday at
about 6,950. Hourly steps peak near 6 PM at about 592. The participant intervals overlap broadly,
so these rankings should not be treated as universal optimal times.

The actionable interpretation is narrower: midday and early evening are plausible candidate
windows for a notification experiment. Personal timing based on a user's own history is more
defensible than sending every user a message at 6 PM.

**Evidence grade:** moderate for the sample's time pattern, low for product impact.

![Participant weighted weekday activity](../output/figures/03_weekday_steps.png)
![Participant weighted hourly activity](../output/figures/04_hourly_steps.png)

### Finding 3: repeated days create false precision in the sleep analysis

| Estimand | Hours per 1,000 steps | 95% interval | Participants |
| --- | ---: | ---: | ---: |
| Naive day level | minus 0.085 | minus 0.129 to minus 0.041 | 18 |
| Within participant | minus 0.058 | minus 0.127 to 0.015 | 18 |
| Between participant | minus 0.076 | minus 0.346 to 0.195 | 18 |

The naive interval looks decisive because it treats 394 repeated days like independent evidence.
The participant aware intervals are wider and include zero. The defensible conclusion is that this
sample does not identify a reliable activity and sleep association.

No causal interpretation is warranted. Work schedules, health, device wear, weekends, and sleep
logging behavior could all affect both steps and recorded sleep.

**Evidence grade:** low and inconclusive.

![Activity and sleep estimates](../output/figures/05_sleep_by_steps.png)

### Finding 4: participant weighting changes magnitude more than direction

| Metric | Observation weighted | Participant weighted | Difference |
| --- | ---: | ---: | ---: |
| Average daily steps | 7,671 | 7,556 | minus 115 |
| Average sedentary hours | 16.49 | 16.63 | 0.14 |
| Share of 10k step days | 32.4% | 31.1% | minus 1.3 percentage points |

The main descriptive conclusions survive equal participant weighting, but the sensitivity table
makes the estimand explicit and prevents heavier loggers from silently defining the result.

**Evidence grade:** moderate for this sample.

![Activity intensity mix](../output/figures/06_activity_mix.png)

## 5. Product experiment roadmap

The historical data cannot estimate product lift. It can narrow the hypotheses worth testing.

| Hypothesis | Proposed intervention | Primary metric | Guardrail |
| --- | --- | --- | --- |
| Routine timed prompts increase meaningful movement | Prompt near each user's historically active midday or evening window | Incremental active minutes per user day | Prompt opt out rate |
| A movement and recovery summary improves engagement | Weekly summary pairing movement consistency with sleep logging | Four week retained weekly active users | Notification dismissals and sleep opt outs |
| Passive defaults increase sleep coverage without reducing trust | Clear opt in setup with a privacy explanation | Share of eligible nights with a sleep record | Consent abandonment and feature disablement |

All three should be randomized at the user level. Sample size should be powered using current
Bellabeat baseline variance and a prespecified minimum meaningful effect, not the 2016 Fitbit
sample.

## 6. Limitations

1. The sample contains only 33 participants and is not documented as representative.
2. The data is from 2016 and may not describe current devices or customers.
3. Recruitment, demographics, geography, health, and device model are unavailable.
4. Sleep logging is selective, and the primary sleep analysis includes only 18 participants.
5. Fixed effects remove stable participant differences but not time varying confounding.
6. Bootstrap intervals reflect the observed participant sample, not all sources of uncertainty.
7. The archive is obtained from a pinned third party mirror because the original hosted download
   is not used programmatically.
8. The sleep date alignment supplied by the source may not perfectly distinguish the preceding
   night from the following activity day.

## 7. Reproduction

Run `Rscript tests/test_pipeline.R`. The command verifies the source files, rebuilds every summary
and figure, and checks the central scientific assertions. GitHub Actions runs the same workflow on
every pull request.

The central contribution of this study is not a marketing slogan. It is a disciplined boundary
between what the historical data shows, what remains uncertain, and what a product team should
test next.
