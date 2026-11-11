# Data Validation Tests

## Test 1: Trip ID Uniqueness

**Objective:** Ensure every trip appears only once after combining and deduplicating the initial and incremental datasets.

```sql
-- Test 1: Validate Trip ID Uniqueness

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT trip_id) AS unique_trip_ids,
    COUNT(trip_id) - COUNT(DISTINCT trip_id) AS duplicate_trip_ids,
    SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) AS null_trip_ids,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT trip_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM temp_trips_deduplicated;
```

**Expected result:** `PASS`, with no duplicate or NULL trip IDs.

**Why it matters:** Duplicate trips can inflate Average Weekly Trips and distort Average Trip Price and Shared Trip Rate.

## Test 2: Trip Timestamp Validity

**Objective:** Ensure trips have valid timestamps for completion-week reporting.

```sql
-- Test 2: Validate Trip Timestamps

SELECT
    COUNT(*) AS total_records,
    SUM(
        CASE
            WHEN trip_start_timestamp IS NULL
              OR trip_end_timestamp IS NULL
              OR trip_end_timestamp < trip_start_timestamp
            THEN 1 ELSE 0
        END
    ) AS invalid_timestamp_trips,
    CASE
        WHEN SUM(
            CASE
                WHEN trip_start_timestamp IS NULL
                  OR trip_end_timestamp IS NULL
                  OR trip_end_timestamp < trip_start_timestamp
                THEN 1 ELSE 0
            END
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM temp_trips_deduplicated;
```

**Expected result:** `PASS` if the trusted dataset contains only trips with valid timestamps.

**Interpretation:** If this test fails on the raw deduplicated dataset, it does not necessarily mean the canonical metrics are wrong. Invalid trips can be excluded through the eligibility rules, with the affected count documented.

