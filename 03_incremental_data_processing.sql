---------- Combining Incremental Trip Data with Initial Trip Data ----------

WITH combined_trips AS (
    SELECT *, 'initial' AS source_file
    FROM raw.trips_initial

    UNION ALL BY NAME

    SELECT *, 'incremental' AS source_file
    FROM read_parquet('C:\Users\Harish\OneDrive\Desktop\Interview Preps\Uber Take Home Assignment\incremental_trips.parquet')
    WHERE pickup_community_area in (24,41,43,56)
)

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT trip_id) AS unique_trips,
    COUNT(*) - COUNT(DISTINCT trip_id) AS duplicate_trip_id_rows
FROM combined_trips; 

---------- Duplicate Records Validation ----------
-- Check for duplicate trip IDs across the initial and incremental datasets.
-- Duplicate records were identified in both datasets.

WITH combined_trips AS (
    SELECT *, 'initial' AS source_file
    FROM raw.trips_initial

    UNION ALL BY NAME

    SELECT *, 'incremental' AS source_file
    FROM read_parquet('C:\Users\Harish\OneDrive\Desktop\Interview Preps\Uber Take Home Assignment\incremental_trips.parquet')
    WHERE pickup_community_area in (24,41,43,56)
)

SELECT
    trip_id,
    COUNT(*) AS duplicate_count,
    COUNT(DISTINCT source_file) AS source_count
FROM combined_trips
GROUP BY trip_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

---------- Identifying Overlapping Trip IDs Between Initial and Incremental Datasets ----------
-- Identify trip IDs present in both datasets to prevent double-counting
-- when consolidating the initial and incremental deliveries.

SELECT
    inc.trip_id,
    COUNT(*) AS matching_pairs
FROM read_parquet('C:\Users\Harish\OneDrive\Desktop\Interview Preps\Uber Take Home Assignment\incremental_trips.parquet') inc
INNER JOIN raw.trips_initial i
ON inc.trip_id = i.trip_id
WHERE inc.pickup_community_area IN (24, 41, 43, 56)
GROUP BY inc.trip_id
ORDER BY matching_pairs DESC;


----------  Consolidating and Deduplicating Initial and Incremental Trip Data ---------- 
-- Combine both deliveries and remove duplicate trip IDs.
-- Prioritize incremental records to incorporate the latest available trip information.
-- Derive date dimensions to support subsequent metric calculations and trend analysis. 

-- Consolidating and Deduplicating Initial and Incremental Trip Data --
-- Combine both deliveries and retain one record per trip_id.

CREATE OR REPLACE TEMP TABLE temp_trips_deduplicated AS

WITH combined_trips AS (
	SELECT *,
        1 AS source_priority,
        ROW_NUMBER() OVER (ORDER BY trip_id) AS source_row_number
    FROM raw.trips_initial

    UNION ALL BY NAME

    SELECT * ,
        2 AS source_priority
    FROM read_parquet('C:\Users\Harish\OneDrive\Desktop\Interview Preps\Uber Take Home Assignment\incremental_trips.parquet',file_row_number = TRUE)
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY trip_id ORDER BY source_priority DESC) AS rn
    FROM combined_trips
)

SELECT
    trip_id,
    DATE(DATE_TRUNC('month', trip_start_timestamp)) AS trip_start_month,
    DATE(DATE_TRUNC('week', trip_start_timestamp)) AS trip_start_week,
    DATE(trip_start_timestamp) AS trip_start_dt,
    trip_start_timestamp,
    DATE(DATE_TRUNC('month', trip_end_timestamp)) AS trip_end_month,
    DATE(DATE_TRUNC('week', trip_end_timestamp)) AS trip_end_week,
    DATE(trip_end_timestamp) AS trip_end_dt,
    trip_end_timestamp,
    trip_seconds,
    trip_miles,
    percent_time_chicago,
    percent_distance_chicago,
    pickup_community_area,
    dropoff_community_area,
    fare,
    tip,
    additional_charges,
    trip_total,
    shared_trip_authorized,
    shared_trip_match,
    trips_pooled
FROM deduplicated
WHERE rn = 1;

-- Validate uniqueness after deduplication --

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT trip_id) AS unique_trip_ids,
    COUNT(*) FILTER (WHERE trip_id IS NULL) AS null_trip_ids,
    COUNT(*) - COUNT(DISTINCT trip_id)
        - COUNT(*) FILTER (WHERE trip_id IS NULL) AS duplicate_records
FROM temp_trips_deduplicated;
