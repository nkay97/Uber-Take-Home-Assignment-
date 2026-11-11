# Uber Mobility Metrics Reconciliation

**Senior Data Analyst Take-Home Assignment**

## Overview

Two weekly dashboards report different results for the same Chicago mobility metrics. This project investigates why the numbers differ, defines a consistent set of metrics, and compares the historical period with the latest data.

The analysis covers **four Chicago pickup community areas: 24, 41, 43, and 56**. It uses an initial six-week delivery (**March 3–April 13, 2025**) and an incremental delivery covering primarily the following two weeks (**April 14–27, 2025**), with some overlapping records.

## What I did

1. Checked the initial trip data for missing values, duplicates, invalid timestamps, and unusual prices.
2. Recreated the logic behind Dashboard A and Dashboard B to identify differences in their reported metrics.
3. Combined the initial and incremental deliveries, keeping one record per trip ID and giving priority to the incremental record.
4. Defined canonical metrics and compared the six historical weeks with the latest two weeks.
5. Ran a sensitivity check and validation queries to understand how data-quality and definition choices affect the results.

## Why the dashboards disagree

The reports use different calculation rules:

| Area | Dashboard A | Dashboard B |
| --- | --- | --- |
| Reporting week | Trip start timestamp | Trip end timestamp |
| Trip population | Does not require a known dropoff community area | Excludes trips with a NULL dropoff community area |
| Average trip price | Average `fare` | Average `trip_total` |
| Shared-trip rate | `shared_trip_authorized = TRUE` | `shared_trip_match = TRUE` |

For the initial reporting period, **Dashboard A reports 965,201 trips**, compared with **880,598 in Dashboard B**—a difference of **84,603 trips (8.8% of Dashboard A)**. The missing-dropoff rule is one likely contributor to this gap, but it has not been confirmed as the complete explanation.

The price and shared-trip measures also answer different questions: fare is not the same as total trip price, and authorization to share is not the same as an actual shared match.

See [dashboard reconciliation findings](03_dashboard_reconciliation_findings.md) for the full discussion.

## Canonical metrics

I used the following definitions for the historical-versus-latest comparison:

| Metric | Definition |
| --- | --- |
| **Average Weekly Trips** | Number of distinct eligible trips divided by the number of weeks in the period: **6** for Historical and **2** for Latest |
| **Average Trip Price** | Average `trip_total` across eligible trips with a non-NULL price; zero-priced trips are retained |
| **Actual Shared Trip Rate** | Eligible trips with `shared_trip_match = TRUE` divided by all eligible trips |

**Common rules:** Use the trip end timestamp to assign the reporting period; include only the four selected pickup areas; require a non-NULL trip ID and valid start/end timestamps; retain one row per trip ID; and keep otherwise valid trips even when the dropoff community area is NULL. A NULL shared-trip match is not counted as a confirmed match.

Average Weekly Trips is used instead of total trip volume because the comparison periods have different lengths.

See [canonical metric definitions and SQL](04_canonical_metric_definition.md).

## Key findings

- **Area 24 had the most trips** in both periods. Average weekly trips went from about **79.7K** in the historical period to **76.1K** in the latest period.
- **Area 56 had the highest average trip price**, at **$43.13** historically and **$42.67** in the latest period.
- **The missing-dropoff filter has a large effect in Area 56.** Excluding those trips reduces average weekly trips by **31.88%** in the historical period and **29.69%** in the latest period. The impact is much smaller in Areas 24 and 41.

Overall, average weekly trip activity and trip prices were fairly stable across these two periods, although the direction and size of changes varied by area.

### Recommendation for Operations

Use one agreed set of definitions for trip activity, average price, and actual shared matches. Keep valid trips with unknown dropoff areas in the main trip count, and track missing dropoff information separately—especially in Area 56. This will make weekly comparisons easier to trust.

## Repository files

| File | Purpose |
| --- | --- |
| [01_data_validation.sql](01_data_validation.sql) | Initial checks for NULLs, duplicates, prices, and timestamps |
| [02_dashboard_reconciliation.sql](02_dashboard_reconciliation.sql) | Reconstructs both dashboard definitions and compares results |
| [03_dashboard_reconciliation_findings.md](03_dashboard_reconciliation_findings.md) | Explains the reasons for dashboard differences |
| [04_canonical_metric_definition.md](04_canonical_metric_definition.md) | Documents trusted metric definitions, calculation SQL, and key findings |
| [05_incremental_data_processing.sql](05_incremental_data_processing.sql) | Combines initial and incremental data and creates a deduplicated temporary table |
| [06_sensitivity_check.md](06_sensitivity_check.md) | Tests the impact of excluding NULL dropoff community areas |
| [07_data_quality_check.md](07_data_quality_check.md) | Focused data-quality checks and results |
| [08_data_validation_tests.md](08_data_validation_tests.md) | Reproducible SQL validation tests |

## How to reproduce

The SQL uses **DuckDB**. The assignment data is not included in this repository.

1. Load the supplied initial trip dataset into `raw.trips_initial`, and the two supplied weekly reports into `reporting.dashboard_a_weekly` and `reporting.dashboard_b_weekly`.
2. Run the initial checks in `01_data_validation.sql` and the reconciliation queries in `02_dashboard_reconciliation.sql`.
3. Update the local Parquet file path in `05_incremental_data_processing.sql`, then run its consolidation step to create `temp_trips_deduplicated`.
4. In the **same DuckDB session**, run the canonical metrics query in `04_canonical_metric_definition.md`, followed by the sensitivity query in `06_sensitivity_check.md`.
5. Run the checks in `07_data_quality_check.md` and the validation tests in `08_data_validation_tests.md`. Review any failed tests and document the affected records.

The repository contains SQL and a written analysis rather than a single automated pipeline, so the source tables and local file path need to be configured before running the queries.

## Assumptions and limitations

- The data represents **four selected community areas**, not all Chicago trips.
- A missing dropoff community area may reflect incomplete location information or a destination outside mapped areas; it should not automatically be treated as an invalid trip.
- The full cause of Dashboard B's lower trip count has not been independently confirmed beyond the identified logic differences.
- The latest period is only two weeks, so the comparison is descriptive and does not establish a longer-term trend.
