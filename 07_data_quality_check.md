# Data Quality Validation

## 1. Duplicate Trip ID Validation

**Purpose:** Check whether duplicate `trip_id` values remain after combining the initial and incremental datasets. Duplicate trips can inflate trip volume and affect other metrics.

```sql
-- Check 1: Duplicate Trip ID Validation

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT trip_id) AS unique_trip_ids,
    SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) AS null_trip_ids,
    COUNT(trip_id) - COUNT(DISTINCT trip_id) AS duplicate_trip_ids
FROM temp_trips_deduplicated;
```
<img width="517" height="202" alt="Screenshot 2026-11-11 195237" src="https://github.com/user-attachments/assets/b4d01814-b7de-4dc5-b1af-baf1e4034811" />


## 2. Timestamp and Price Validation

**Purpose:** Identify invalid timestamps that could affect completion-week reporting and missing or unusual prices that could affect Average Trip Price.

```sql
-- Check 2: Timestamp and Price Validation

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN trip_start_timestamp IS NULL OR trip_end_timestamp IS NULL THEN 1 ELSE 0 END) AS missing_timestamps,
    SUM(CASE WHEN trip_end_timestamp < trip_start_timestamp THEN 1 ELSE 0 END) AS invalid_timestamp_order,
    SUM(CASE WHEN trip_total IS NULL THEN 1 ELSE 0 END) AS null_trip_total,
    SUM(CASE WHEN trip_total = 0 THEN 1 ELSE 0 END) AS zero_price_trips,
    SUM(CASE WHEN trip_total < 0 THEN 1 ELSE 0 END) AS negative_price_trips
FROM temp_trips_deduplicated;
```
<img width="722" height="262" alt="Screenshot 2026-11-11 195838" src="https://github.com/user-attachments/assets/ec7cbaeb-59da-4031-84c7-8a1e658645ca" />


