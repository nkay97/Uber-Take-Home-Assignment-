# AI Use Disclosure

## How I Used AI

I used ChatGPT and Microsoft Copilot as supporting tools during this assignment.

**ChatGPT:**
- Helped me understand parts of the assignment and clarify analytical concepts.
- Assisted with reviewing SQL queries, building complex query logic, and troubleshooting errors.
- Helped me explore possible reasons for the differences between the two dashboards.
- Provided guidance on metric calculations, data-quality checks, and sensitivity analysis.
- Assisted with creating charts for the canonical metrics.

**Microsoft Copilot:**
- Helped me organize and document the analysis, findings, and insights.
- Assisted with improving the clarity and structure of the written explanations.

## What I Verified Independently

I developed the SQL query logic, executed the queries against the provided datasets, and reviewed the results to verify the calculations.

I compared the reconstructed metrics with the existing dashboards and investigated differences in trip counts, average trip prices, and shared-trip rates.

I also performed data-quality checks to identify potential issues with duplicates, missing values, and inconsistent records. I carried out a sensitivity analysis to understand how alternative eligibility rules affected the reported trip volume.

I structured the overall approach for dashboard reconciliation and historical performance analysis.

The findings and conclusions presented in the submission are based on the actual query results, not AI-generated estimates.

## Analytical Decisions

The following decisions were made during my analysis:

- **Reporting period:** I used trip completion timestamps to assign trips to their respective reporting periods.

- **Historical comparison:** An AI tool suggested comparing the latest data against the historical baseline provided for January 2025. I decided not to use this as the primary comparison because the difference in months could introduce seasonal effects and make the results less comparable. Instead, I used the six weeks of initial data (March 3–April 13) as the historical period and compared it against the latest two weeks (April 14–27).

- **Average Weekly Trips:** I chose Average Weekly Trips instead of total Trip Volume for the period comparison. Since the historical period covers six weeks and the latest period covers only two weeks, comparing total trip counts directly would be misleading. Average Weekly Trips provides a more meaningful comparison.

- **Average Trip Price:** I used `trip_total` rather than `fare` because it represents the total reported trip amount, including tips and additional charges.

- **Shared Trip Rate:** I used `shared_trip_match` rather than `shared_trip_authorized` to measure trips that were actually matched for sharing.

- **Missing dropoff locations:** I included trips with NULL `dropoff_community_area` values because the analysis focuses on pickup locations. A missing dropoff area does not necessarily mean the trip is invalid.

- **Sensitivity analysis:** I tested an alternative Trip Volume definition that excludes trips with missing dropoff community areas to understand how this assumption affects the results.

## Recommendation for Operations

I recommend using a single standardized dashboard with consistent definitions for Average Weekly Trips, Average Trip Price, and Shared Trip Rate.
Using consistent metric definitions will help Operations track demand, pricing, and shared-trip activity more reliably across community areas and make better-informed decisions.
