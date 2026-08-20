# Power Query import pattern

Create a text parameter named `ProjectRoot` that points to the local repository root. For each CSV, create a blank query and adapt this pattern:

```powerquery
let
    Source = Csv.Document(
        File.Contents(ProjectRoot & "/powerbi/data/participant_summary.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Headers = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),
    Typed = Table.TransformColumnTypes(
        Headers,
        {
            {"participant_id", type text},
            {"activity_days", Int64.Type},
            {"avg_steps", type number},
            {"avg_active_minutes", type number},
            {"avg_sedentary_hours", type number},
            {"step_goal_rate", Percentage.Type},
            {"sleep_log_rate", Percentage.Type},
            {"weight_log_rate", Percentage.Type},
            {"engagement_segment", type text}
        }
    )
in
    Typed
```

Use whole numbers for counts and hour fields, decimal numbers for estimates, percentages for rates, and text for identifiers. Keep participant identifiers as text so Power BI does not aggregate them.
