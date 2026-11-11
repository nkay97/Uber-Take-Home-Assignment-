## Canonical Metric Definitions

To ensure consistent reporting and comparison between the historical and latest periods, the following three canonical metrics have been defined.

The historical dataset covers **6 weeks (March 3 – April 13, 2025)**, while the latest dataset covers **2 weeks (April 14 – April 27, 2025)**.

Since the reporting periods have different durations, **Average Weekly Trips is used instead of total Trip Volume** for the historical-versus-latest comparison. This normalizes trip activity and enables a more meaningful comparison.

| Metric Name | Canonical Metric Definition |
|---|---|
| **Average Weekly Trips** | Total number of unique eligible completed trips divided by the number of weeks in the reporting period (6 for Historical and 2 for Latest). |
| **Average Trip Price** | Average `trip_total` across eligible completed trips. Includes fare, tips, and additional charges. Trips with NULL `trip_total` are excluded from the average calculation, while zero-priced trips are retained. |
| **Actual Shared Trip Rate** | Number of eligible completed trips where `shared_trip_match = TRUE` divided by the total number of eligible completed trips. |

### Common Eligibility and Reporting Rules

- **Reporting granularity:** Reporting period × Pickup Community Area.
- **Trip completion:** Trips are attributed to the reporting period based on `trip_end_timestamp`.
- **Geographic scope:** Includes trips originating from the four selected Chicago pickup community areas (24, 41, 43, and 56).
- **Dropoff location:** Trips with NULL `dropoff_community_area` are included in all three metrics. These may include trips ending outside Chicago or trips with unavailable dropoff information. A NULL dropoff area alone does not confirm that a trip ended outside Chicago.
- **Duplicate handling:** Only one record per `trip_id` is retained after deduplication.
- **Trip validity:** Trips must have a valid trip ID, non-NULL start and end timestamps, and an end timestamp greater than or equal to the start timestamp.
- **Shared-trip NULL handling:** Trips with NULL `shared_trip_match` remain in the denominator but are not counted as confirmed shared matches.

### Rationale

These definitions ensure that all three metrics use a consistent eligible-trip population. Including trips with missing dropoff community areas avoids excluding otherwise valid trips originating from the selected Chicago pickup areas.

Average Weekly Trips provides a normalized measure of trip activity across the unequal reporting periods, while Average Trip Price and Actual Shared Trip Rate provide insights into customer spending and realized shared-trip activity.



## Query to calculate Canonical Metrics

The following query combines initial and incremental trip data and removes duplicate records by prioritizing incremental data.

```sql
WITH eligible AS (
    SELECT
        trip_id,
        trip_end_timestamp,
        pickup_community_area,
        trip_total,
        shared_trip_match,
        CASE
            WHEN trip_end_timestamp >= TIMESTAMP '2025-03-03'
             AND trip_end_timestamp < TIMESTAMP '2025-04-14'
                THEN 'Historical'
            WHEN trip_end_timestamp >= TIMESTAMP '2025-04-14'
             AND trip_end_timestamp < TIMESTAMP '2025-04-28'
                THEN 'Latest'
        END AS period
    FROM temp_trips_deduplicated
    WHERE trip_id IS NOT NULL
      AND trip_start_timestamp IS NOT NULL
      AND trip_end_timestamp >= trip_start_timestamp
      AND pickup_community_area IN (24, 41, 43, 56)
),

period_metrics AS (
    SELECT
        pickup_community_area,
        period,
        COUNT(DISTINCT trip_id) AS trip_volume,
        COUNT(trip_total) AS priced_trips,
        SUM(trip_total) AS total_price,
        SUM(CASE WHEN shared_trip_match = TRUE THEN 1 ELSE 0 END) AS matched_trips,
        CASE WHEN period = 'Historical' THEN 6 ELSE 2 END AS weeks
    FROM eligible
    WHERE period IS NOT NULL
    GROUP BY 1, 2
)

SELECT
    pickup_community_area,
    period,
    trip_volume,
    ROUND(trip_volume * 1.0 / weeks, 2) AS avg_weekly_trips,
    ROUND(total_price / NULLIF(priced_trips, 0), 2) AS avg_trip_price,
    ROUND(matched_trips * 1.0 / NULLIF(trip_volume, 0), 4) AS shared_trip_rate
FROM period_metrics
ORDER BY pickup_community_area, period;
```
