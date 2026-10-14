# Maven Premium Coffee Pilot

This data insights project aims to decide whether a coffee shop (Maven) should keep a new pilot coffee, Jamaican Coffee River, on the menu. It uses a combination of sales transaction data for six months across three stores, real bean import prices and a hypothetical roaster markup and production costs. I present a decision framework of whether to keep, modify or discontinue the Jamaican pilot.


### Summary of Findings

My recommendation is to modify the current price of Jamaican by switching to a cheaper roaster and raising the price by $0.25. These changes would have added $8,405 over the six months. More details are in the [business_brief](business_brief.md).

Jamaican was the top seller by revenue in every store, making up 26.5% of coffee sales. The biggest issue with this coffee is its price. Jamaican’s beans cost over four times as much as Brazilian’s, but its price is only slightly higher, so it keeps 52% of each sale as margin vs. 75% to 83% for the other coffees. This difference in margin cost the company $6,741 over six months.

**For this project I had a set of objectives I wanted to acomplish. They are:**
1. Estimate the cost and margin per cup for each coffee and size.
2. Compare Jamaican with Brazilian, Colombian and Ethiopian coffee on units, revenue share and margin.
3. Check whether results differ by store.
4. Track Jamaican's monthly share of coffee sales, adjusted for overall store growth.
5. Test price scenarios: Jamaican price increases of $0.25 and $0.50, and switching to cheaper roaster at 2.5x or 2x markup 

**I scoped the project to include** the four single-origin brewed coffees, in every size. Costs cover beans plus cup, lid and sleeve. While things like espresso, blends, tea, cream, sugar, waste, card fees, labor and rent reamined out of scope.

#### Data
1. **[Maven transactions](https://mavenanalytics.io/data-playground/coffee-shop-sales):** the public Maven Roasters dataset, 149,116 transaction lines, January 1 to June 30, 2023, from three New York stores (Astoria, Hell's Kitchen, Lower Manhattan).
2. **[WITS imports](https://wits.worldbank.org/trade/comtrade/en/country/USA/year/2023/tradeflow/Imports/partner/ALL/product/090111):** World Bank trade data (World Integrated Trade Solution) on 2023 US imports of green, unroasted coffee, giving the average price per kg for each origin country.
3. [**Cost-per-cup table**](coffee_cost_per_cup.csv): built for this project, with one row per coffee and size (12 in total) estimating what each cup costs in beans and packaging. The formula and assumptions are in the Business Brief.

### Dataset limitations
- The sales data has no costs, so bean cost is estimated from 2023 import prices plus an assumed roaster markup. The import prices also cover all of 2023, while sales cover only January to June.
- Prices never changed and there are no customer IDs, so the data can't show how customers would react to a price increase or whether Jamaican Coffee buyers come back. The price scenarios assume sales would have held.
- Six months isn't long enough to see seasonal patterns. Jamaican also sold from the first day, so there's no before-and-after to show whether it pulled sales from the other coffees.

### Files

| File | What it is |
| --- | --- |
| [business_brief.md](business_brief.md) | Findings|
| [data_dictionary.md](data_dictionary.md) | Every table and column use in this project |
| [source_to_target_mapping.md](source_to_target_mapping.md) | How the sources join into the analysis view, plus validation results |
| [data_issues_log.md](data_issues_log.md) | Data problems found and how each was fixed |
| [reflections.md](reflections.md) | Personal write-up on the project |
| [01_setup.sql](01_setup.sql) | One-time setup: renames, type fixes, analysis view |
| [02_validation.sql](02_validation.sql) | Data quality checks |
| [03_analysis.sql](03_analysis.sql) | Queries related to business questions |
| [04_scenarios.sql](04_scenarios.sql) | Adjusted price and roaster scenarios |
| [**Cost-per-cup table**](coffee_cost_per_cup.csv) | product costs assumed for this project |

### How to run

1. Use SQL Server 2016 SP1 or later.
2. Import the Maven transactions, WITS 2023 and coffee_cost_per_cup.csv as salesrevenue, WITS2023 and coffee_unit_costs.
3. Run 01_setup.sql once, then 02_validation.sql to confirm the checks, then 03 and 04.
