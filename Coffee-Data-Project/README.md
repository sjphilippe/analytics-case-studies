# Maven Premium Coffee Pilot

This portfolio case study explores whether Maven should keep, modify, or discontinue Jamaican Coffee River as a hypothetical menu pilot. I combined six months of sales data across three stores with coffee import prices and estimated bean and packaging costs to evaluate demand, margins, and pricing options.

**Tools:** SQL Server, SQL, and Claude for coding and documentation assistance.

**My role:** I defined the business question, selected the sources and cost assumptions, ran every query in SQL Server, checked the outputs, and made the final recommendation. Claude helped draft SQL, documentation, and supporting calculations. See [how I worked with Claude.](reflections.md) 


### Summary of Findings


My recommendation is to keep Jamaican Coffee River on the menu while exploring a cheaper roaster and a $0.25 price increase. Under the modeled cost assumptions, reducing the roaster multiplier from 3× to 2× and holding sales volume constant would have added an estimated $8,405 in margin over six months. This is a scenario result, not realized savings. See the [business brief](business_brief.md) for the findings and assumptions.

Jamaican was the top seller by revenue in every store, making up 26.5% of coffee sales.Jamaican’s estimated bean cost was over four times Brazilian’s, but its selling price was only slightly higher. Under the cost model, Jamaican retained about 52% of revenue after bean and packaging costs, compared with 75% to 83% for the other coffees. Applying the other coffees’ average margin per cup at each size to Jamaican’s sales volume produced a $6,741 benchmark gap over six months

**For this project I had a set of objectives I wanted to accomplish. They are:**
1. Estimate the cost and margin per cup for each coffee and size.
2. Compare Jamaican with Brazilian, Colombian and Ethiopian coffee on units, revenue share and margin.
3. Check whether results differ by store.
4. Track Jamaican's monthly share of coffee sales, adjusted for overall store growth.
5. Test price scenarios: Jamaican price increases of $0.25 and $0.50, and switching to cheaper roaster at 2.5x or 2x cost multiplier.

**I scoped the project to include** the four single-origin brewed coffees, in every size. Modeled costs include beans, cups, lids, and sleeves. Espresso, blends, and tea are outside the product scope. Cream, sugar, waste, card fees, labor, and rent are excluded from the cost model, so the reported margin is not net profit.

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
