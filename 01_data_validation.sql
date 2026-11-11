-- 1. Check for NULL values in important columns --
-- Check how many records have missing values in important columns.
-- This helps us understand whether missing data could affect our analysis.

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) AS null_trip_ids,
    SUM(CASE WHEN trip_start_timestamp IS NULL THEN 1 ELSE 0 END) AS null_start_time,
    SUM(CASE WHEN trip_end_timestamp IS NULL THEN 1 ELSE 0 END) AS null_end_time,
    SUM(CASE WHEN trip_seconds IS NULL THEN 1 ELSE 0 END) AS null_trip_seconds,
    SUM(CASE WHEN trip_miles IS NULL THEN 1 ELSE 0 END) AS null_trip_miles,
    SUM(CASE WHEN pickup_community_area IS NULL THEN 1 ELSE 0 END) AS null_pickup_area,
    SUM(CASE WHEN dropoff_community_area IS NULL THEN 1 ELSE 0 END) AS null_dropoff_area,
    SUM(CASE WHEN fare IS NULL THEN 1 ELSE 0 END) AS null_fare,
    SUM(CASE WHEN trip_total IS NULL THEN 1 ELSE 0 END) AS null_trip_price,
    SUM(CASE WHEN shared_trip_match IS NULL THEN 1 ELSE 0 END) AS null_shared_match ,
    SUM(CASE WHEN shared_trip_authorized IS NULL THEN 1 ELSE 0 END) AS null_shared_trip_authorized
FROM raw.trips_initial;  

-- 2. Check for duplicate trip IDs -- 

-- Check whether trip IDs are unique across the dataset.
-- Ideally, each trip should have one unique trip ID.
-- This helps identify whether duplicate records could inflate the trip count.

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT trip_id) AS unique_trip_ids,
    SUM(CASE WHEN trip_id IS NULL THEN 1 ELSE 0 END) AS null_trip_ids
FROM raw.trips_initial; 

-- 3.Check for invalid numeric values -- 

-- Check whether trip distance, duration, price and Chicago percentages
-- contain values outside their expected ranges.
-- These issues could affect average trip price and other calculations.

SELECT
    SUM(CASE WHEN trip_miles < 0 THEN 1 ELSE 0 END) AS negative_distance,
    SUM(CASE WHEN trip_seconds < 0 THEN 1 ELSE 0 END) AS negative_duration,
    SUM(CASE WHEN trip_total < 0 THEN 1 ELSE 0 END) AS negative_price,
    SUM(CASE WHEN percent_time_chicago < 0 OR percent_time_chicago > 1 THEN 1 ELSE 0 END) AS invalid_time_percentage,
    SUM(CASE WHEN percent_distance_chicago < 0 OR percent_distance_chicago > 1 THEN 1 ELSE 0 END) AS invalid_distance_percentage
FROM raw.trips_initial;

-- 4.Validate total trip price -- 

-- Check whether the total trip price matches the sum of fare, tip and additional charges.
-- A difference greater than 0.01 is considered a price mismatch.
-- This helps us identify possible inconsistencies in pricing data.

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN fare IS NOT NULL AND tip IS NOT NULL AND additional_charges IS NOT NULL AND trip_total IS NOT NULL AND ABS(trip_total - (fare + tip + additional_charges)) > 0.01 THEN 1 ELSE 0 END) AS price_mismatch_count
FROM raw.trips_initial;

-- 5.Validate trip timestamps and duration --  

-- Check whether trip timestamps and duration values are valid.
-- This helps identify incorrect timestamps and trips that span multiple weeks.
-- Cross-week trips are important because they can affect weekly reporting.

SELECT
    -- Trips where the end time is earlier than the start time
    SUM(CASE WHEN trip_end_timestamp < trip_start_timestamp THEN 1 ELSE 0 END) AS end_before_start,
    -- Trips where the recorded duration is zero seconds
    SUM(CASE WHEN trip_seconds = 0 THEN 1 ELSE 0 END) AS zero_duration_trips,
    -- Trips that start in one week and end in another week
    SUM(CASE WHEN DATE_TRUNC('week', trip_start_timestamp) <> DATE_TRUNC('week', trip_end_timestamp) THEN 1 ELSE 0
    END) AS cross_week_trips
FROM raw.trips_initial;


