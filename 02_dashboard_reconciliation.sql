-- Dashboard Reconciliation --
-- Recreate the weekly metrics from Dashboard A and Dashboard B using the raw trip data.
-- The objective is to understand how differences in metric definitions and filtering conditions affect the reported results.


-- 1. Dashboard A Summary --
-- Calculate weekly trip count, average trip price, and shared trip rate for each pickup community area.
-- Trip count includes all unique trips, average trip price is calculated using fare,
-- and shared trip rate is based on trips where shared_trip_authorized is TRUE.

SELECT
    DATE_TRUNC('week', trip_start_timestamp)::DATE AS week_start,
    pickup_community_area,
    COUNT(DISTINCT trip_id) AS trip_count,
    ROUND(AVG(fare), 2) AS avg_trip_price,
    ROUND(COUNT(*) FILTER (WHERE shared_trip_authorized = TRUE) * 1.0 / NULLIF(COUNT(*), 0), 2) AS shared_trip_rate
FROM raw.trips_initial
GROUP BY 1, 2
ORDER BY 1, 2;


-- 2. Dashboard B Summary --
-- Calculate weekly trip count, average trip price, and shared trip rate for trips with a valid dropoff community area.
-- Unlike Dashboard A, average trip price is calculated using trip_total instead of fare.
-- Shared trip rate is calculated using shared_trip_match instead of shared_trip_authorized.

SELECT
    DATE_TRUNC('week', trip_end_timestamp)::DATE AS week_start,
    pickup_community_area,
    COUNT(DISTINCT trip_id) AS trip_count,
    ROUND(AVG(trip_total)::NUMERIC, 2) AS avg_trip_price,
    ROUND(SUM(CASE WHEN shared_trip_match = TRUE THEN 1 ELSE 0 END)::NUMERIC / NULLIF(COUNT(*), 0), 2) AS shared_trip_rate
FROM raw.trips_initial
WHERE dropoff_community_area IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;


-- 3. Dashboard A vs. Dashboard B – Metric Variance Analysis --
-- Compare weekly metrics from both dashboards at the pickup community area level.
-- Calculate absolute and percentage differences in trip count, average trip price, and shared trip rate.
-- Dashboard A is used as the baseline for percentage difference calculations.
-- This helps identify which metrics have the largest discrepancies and require further investigation.

SELECT
    a.week_start,
    a.pickup_community_area,
    a_trip_count,
    b_trip_count,
    a_trip_count - b_trip_count AS trip_count_diff,
    ROUND((a_trip_count - b_trip_count) * 100.0 / NULLIF(a_trip_count, 0), 2) AS trip_count_diff_pct,
    a_avg_trip_price,
    b_avg_trip_price,
    a_avg_trip_price - b_avg_trip_price AS avg_trip_price_diff,
    ROUND((a_avg_trip_price - b_avg_trip_price) * 100.0 / NULLIF(a_avg_trip_price, 0), 2) AS avg_trip_price_diff_pct,
    a_shared_trip_rate,
    b_shared_trip_rate,
    a_shared_trip_rate - b_shared_trip_rate AS shared_trip_rate_diff,
    ROUND((a_shared_trip_rate - b_shared_trip_rate) * 100.0 / NULLIF(a_shared_trip_rate, 0), 2) AS shared_trip_rate_diff_pct
FROM (
    SELECT DATE(week_start) AS week_start, pickup_community_area, trip_count AS a_trip_count, ROUND(avg_trip_price, 2) AS a_avg_trip_price, shared_trip_rate AS a_shared_trip_rate
    FROM reporting.dashboard_a_weekly
) a
LEFT JOIN (
    SELECT DATE(week_start) AS week_start, pickup_community_area, trip_count AS b_trip_count, ROUND(avg_trip_price, 2) AS b_avg_trip_price, shared_trip_rate AS b_shared_trip_rate
    FROM reporting.dashboard_b_weekly
) b
ON a.week_start = b.week_start AND a.pickup_community_area = b.pickup_community_area
ORDER BY a.week_start, a.pickup_community_area;

---- Supporting Workbook ---- 
-- https://github.com/nkay97/Uber-Take-Home-Assignment-/blob/main/Metric%20Variance%20Analysis.xlsx
