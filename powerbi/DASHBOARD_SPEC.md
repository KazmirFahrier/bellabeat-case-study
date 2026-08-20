# Dashboard specification

## Page 1: Executive Overview

Purpose: answer what happened, how much confidence to place in it, and what Bellabeat should test next.

Top row cards:

1. Participant Count
2. Participant Weighted Daily Steps
3. Participant Weighted Sedentary Hours
4. 10K Step Day Share

Visuals:

1. Participant weighted steps by weekday with confidence intervals
2. Participant weighted steps by hour
3. Dataset coverage by source
4. Recommendation panel with three product experiments

Required annotation: estimates describe this convenience sample from April 12 to May 12, 2016. They do not establish causal effects or population benchmarks.

## Page 2: Usage Patterns

Purpose: show when activity occurs and how engagement differs across participants.

Filters:

1. Engagement segment
2. Daypart
3. Weekday

Visuals:

1. Weekday steps, active minutes, sedentary hours, and goal rate
2. Hourly steps and intensity by daypart
3. Participant activity days versus average steps
4. Engagement segment counts and average days logged

The participant weighted measure is the default. Observation weighted sensitivity values appear in tooltips.

## Page 3: Data Quality and Evidence

Purpose: make data limitations and analytical uncertainty visible.

Visuals:

1. Executable SQL quality checks with actual and expected values
2. Participant coverage by dataset
3. Observation weighted versus participant weighted estimates
4. Sleep association estimates with confidence intervals
5. Business rule definitions

Use green only for passed checks. The within participant sleep estimate must be labeled inconclusive because its interval includes zero.

## Accessibility and interaction

Use the supplied theme. Keep a white canvas, dark slate text, and teal as the primary series color. Use coral for comparisons and amber for caution. Do not rely on color alone. Add explicit values, descriptive titles, and alt text to each visual.
