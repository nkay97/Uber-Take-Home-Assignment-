```sql
WITH eligible AS (
    SELECT
        trip_id,
        pickup_community_area,
        dropoff_community_area,
        CASE
            WHEN trip_end_timestamp >= TIMESTAMP '2025-03-03'
             AND trip_end_timestamp < TIMESTAMP '2025-04-14'
                THEN 'Historical'
            WHEN trip_end_timestamp >= TIMESTAMP '2025-04-14'
             AND trip_end_timestamp < TIMESTAMP '2025-04-28'
                THEN 'Latest'
        END AS period
    FROM temp_trips_deduplicated
    WHERE pickup_community_area IN (24, 41, 43, 56)
      AND trip_id IS NOT NULL
      AND trip_start_timestamp IS NOT NULL
      AND trip_end_timestamp >= trip_start_timestamp
),

trip_counts AS (
    SELECT
        period,
        pickup_community_area,
        COUNT(DISTINCT trip_id) AS canonical_volume,
        COUNT(DISTINCT CASE WHEN dropoff_community_area IS NOT NULL THEN trip_id ELSE NULL END) AS alternative_volume,
        CASE
            WHEN period = 'Historical' THEN 6
            WHEN period = 'Latest' THEN 2
        END AS weeks
    FROM eligible
    WHERE period IS NOT NULL
    GROUP BY 1, 2
)

SELECT
    period,
    pickup_community_area,
    ROUND(canonical_volume * 1.0 / weeks, 2) AS canonical_avg_weekly_trips,
    ROUND(alternative_volume * 1.0 / weeks, 2) AS alternative_avg_weekly_trips,
    ROUND(100.0 * (alternative_volume - canonical_volume)/ NULLIF(canonical_volume, 0), 2) AS sensitivity_pct
FROM trip_counts
ORDER BY pickup_community_area, period;
```

<img width="665" height="383" alt="Screenshot 2026-11-11 192223" src="https://github.com/user-attachments/assets/8a4ca2cd-7fa4-4e50-9f83-eb22b94e756d" /> 

Sensitivity Check – Key Insights
The sensitivity check looks at how average weekly trips change when trips with missing drop-off community areas are excluded.

1. Community Area 56 has the highest impact. Average weekly trips drop by 31.88% in the Historical period and 29.69% in the Latest period. This shows that a large share of trips in this area have missing drop-off information.

2. The impact is relatively low in Areas 24 and 41, where trip volume decreases by around 3–4%. Area 43 sees a higher reduction of around 8.45% in both periods.

3. The overall trends remain the same. Areas 24, 41, and 43 show a decline in average weekly trips, while Area 56 shows an increase under both definitions. However, the size of the increase in Area 56 changes from 1.43% to 4.69%.

Recommendation
- I would recommend keeping all valid trips in the canonical definition, even if the drop-off community area is missing. Excluding these trips could underreport actual trip activity, especially in Area 56.
- The high number of missing drop-off values in Area 56 is worth investigating separately to understand whether it is due to incomplete location data or trips ending outside the mapped community areas.
