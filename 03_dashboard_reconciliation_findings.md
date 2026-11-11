# Dashboard Reconciliation Assessment

## Objective

This analysis looks at why **Weekly Dashboard A** and **Weekly Dashboard B** show different results for the same mobility metrics. The aim is to understand what is driving those differences and whether they could affect how the business interprets the numbers.

## Investigation Approach

I compared the dashboards at the same reporting level:

- `week_start`
- `pickup_community_area`

The comparison covered three metrics:

1. Trip Volume
2. Average Trip Price
3. Shared Trip Rate

I also recreated the calculations using the underlying trip-level data to check where the dashboard logic differs. The main areas reviewed were trip filters, metric definitions, and how trips are assigned to reporting weeks.

## Findings

### 1. Trip Volume: Different Trip Populations

Dashboard B reports fewer trips than Dashboard A for the initial reporting period.

| Measure | Trips |
| --- | ---: |
| Dashboard A | 965,201 |
| Dashboard B | 880,598 |
| Difference | **84,603** |

Dashboard B's count is **8.8% lower** than Dashboard A's.

One possible reason is that Dashboard B excludes trips where `dropoff_community_area` is missing. This would reduce the number of eligible trips. However, this filter alone has not been confirmed as the full explanation, and other differences in filtering may also contribute.

The gap is particularly large in **Community Area 56**, where Dashboard B reports around **31.9% fewer trips** than Dashboard A.

**Why it matters:** A difference of this size can change how demand is understood, especially when comparing activity across community areas. Someone viewing Dashboard B alone may assume trip demand is lower without realizing that some trips were excluded.

### 2. Average Trip Price: Different Price Fields

The dashboards use different fields to calculate average trip price:

- **Dashboard A:** `AVG(fare)`
- **Dashboard B:** `AVG(trip_total)` after applying its trip filters

These are not the same measure. `fare` represents the fare component of a trip, while `trip_total` also includes other charges and any applicable tips.

**Why it matters:** The two averages answer different questions. Dashboard A is closer to the average fare, while Dashboard B is closer to the average amount charged for a trip. Comparing them as if they were the same metric could give a misleading view of pricing.

### 3. Shared Trip Rate: Authorization vs. Match

The dashboards also use different fields to identify shared trips:

- **Dashboard A:** `shared_trip_authorized = TRUE`
- **Dashboard B:** `shared_trip_match = TRUE`

The first field indicates that sharing was authorized. The second indicates that the trip was matched for sharing. An authorized trip does not necessarily result in a shared match.

**Why it matters:** Dashboard A reflects sharing authorization, while Dashboard B is more relevant for measuring actual shared matches. The rates should not be compared directly without making that distinction clear.

### 4. Weekly Assignment: Trip Start vs. Trip End

The dashboards use different timestamps to assign trips to a reporting week:

- **Dashboard A:** `DATE_TRUNC('week', trip_start_timestamp)`
- **Dashboard B:** `DATE_TRUNC('week', trip_end_timestamp)`

For most trips, this will give the same week. However, trips crossing a week boundary can be counted in different weeks.

For example, a trip starting late on Sunday and ending shortly after midnight on Monday would be counted in the previous week in Dashboard A and the following week in Dashboard B.

**Why it matters:** Even when both dashboards include the same trip, its reporting week can differ. This can affect weekly trip counts and other measures, especially near the start or end of a reporting period.

## Conclusion

The differences between the dashboards appear to come mainly from **which trips are included, how metrics are defined, and which timestamp is used for weekly reporting**.

The key differences identified are:

1. Dashboard B uses a smaller trip population.
2. The dashboards calculate average price using different fields.
3. They measure different stages of shared-trip activity.
4. They assign some trips to different weeks.

Based on these findings, the dashboards seem to represent different views of the trip data rather than simply having calculation errors. However, the complete set of Dashboard B filtering rules still needs to be validated.

**Recommendation:** Agree on one set of metric definitions, trip eligibility rules, and weekly assignment logic for operational reporting. If both definitions are useful, give them separate metric names and explain the difference in the dashboards. This would help stakeholders compare results without confusing differences in logic with changes in business performance.

## Assumptions and Limitations

- The reported counts and percentage differences are based on the initial data period reviewed.
- The missing-dropoff filter is an identified possible contributor to the trip-volume gap, but it has not been shown to explain the entire difference.
- This comparison identifies differences in the dashboard calculations; it does not independently confirm every rule used in Dashboard B.
- Findings are limited to the four selected Chicago community areas in the supplied data and should not be treated as citywide results.
