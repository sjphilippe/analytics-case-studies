# Maven Premium Coffee Pilot

This project aims to decide whether a coffee shop (Maven) should keep a new pilot coffee, Jamaican Coffee River, on the menu. It uses a combination of sales transaction data for six months across three stores, real bean import prices with a hypothetical roaster markup and production costs. I, as the company's data analyst, present a decision framework of whether to keep, modify or discontinue the Jamaican pilot and the price and supplier scenarios agreed at the start of the project. The Director of Operations owns the decision, with Finance consulted on margin and Procurement on supplier costs.

#### Decision framework

| Outcome | Condition | Action |
| --- | --- | --- |
| Keep | Margin per cup at or above the other coffees' average, and share stable or rising | Make permanent at current price |
| Modify | Share healthy but margin below the other coffees' average, or strong results in only one or two stores | Reprice, change sizes, or limit to stronger stores |
| Discontinue | Margin and share both below the other coffees' average across stores | Remove from the menu |
### Summary of Findings

***TLDR: Jamaican's share is stable and its revenue is the highest of the four coffees, but margin per cup is below average at every size and in every store. Decision is to Modify by repricing Jamaican and finding a cheaper roaster.***

Customers at every store location bought Jamaican steadily. It earned more in sales than any of the other three coffees, and about one in four cups of the four coffees sold each month was Jamaican. However, each Jamaican cup earned less than the others. Its beans cost about 4x as much as the cheapest coffee's, but its menu price is only slightly higher. After paying for beans and the cup, a Jamaican coffee keeps about half its price, while the others keep three quarters or more. Over six months, the shop would have made $6,741 more if each Jamaican cup had earned what the other coffees earn on the same size. Bean costs are estimated, but even if they're a third lower than assumed, Jamaican still earns the least per cup.

The recommended outcome is Modify. A cheaper roaster plus a $0.25 price increase would have added $8,405 over the six months and put Jamaican ahead of the other coffees per cup. Further details are in the Business Brief.

#### Objectives & Scope
1. Estimate cost and margin per cup for each coffee and size.
2. Compare Jamaican with Brazilian, Colombian and Ethiopian coffee on units, revenue share and margin.
3. Check whether results differ by store.
4. Track Jamaican's monthly share of coffee sales, adjusted for overall store growth.
5. Test four scenarios: Jamaican price increases of $0.25 and $0.50, a cheaper roaster at 2.5× and 2×, both levers together, and whether the finding holds at a 2× markup.

**In Scope:** the four single-origin brewed coffees, in every size. Costs cover beans plus cup, lid and sleeve.
**Out of Scope:** espresso, blends, tea, food and merchandise. Cream, sugar, waste, card fees, labor and rent.

#### Data
1. **Maven transactions:** the public Maven Roasters dataset, 149,116 transaction lines, January 1 to June 30, 2023, from three New York stores (Astoria, Hell's Kitchen, Lower Manhattan).
2. **WITS imports:** World Bank trade data (World Integrated Trade Solution) on 2023 US imports of green, unroasted coffee, giving the average price per kg for each origin country.
3. **Cost-per-cup table:** built for this project, with one row per coffee and size (12 in total) estimating what each cup costs in beans and packaging. The formula and assumptions are in the Business Brief.

### Dataset limitations
- The sales data has no costs, so bean cost is estimated from 2023 import prices plus an assumed roaster markup. The import prices also cover all of 2023, while sales cover only January to June.
- Prices never changed and there are no customer IDs, so the data can't show how customers would react to a price increase or whether Jamaican buyers come back. The price scenarios assume sales would have held.
- Six months isn't long enough to see seasonal patterns. Jamaican also sold from the first day, so there's no before-and-after to show whether it pulled sales from the other coffees.

### Files

| File | What it is |
| --- | --- |
| [business_brief.md](business_brief.md) | Decision, cost method, assumptions, findings, options and recommendation |
| [data_dictionary.md](data_dictionary.md) | Every table and column |
| [source_to_target_mapping.md](source_to_target_mapping.md) | How the sources join into the analysis view, plus validation results |
| [data_issues_log.md](data_issues_log.md) | Data problems found and how each was fixed |
| [reflections.md](reflections.md) | Personal write-up on the project |
| [01_setup.sql](01_setup.sql) | One-time setup: renames, type fixes, analysis view |
| [02_validation.sql](02_validation.sql) | Data quality checks |
| [03_analysis.sql](03_analysis.sql) | Queries related to business questions |
| [04_scenarios.sql](04_scenarios.sql) | Adjusted price and roaster scenarios |

### How to run

1. Use SQL Server 2016 SP1 or later.
2. Import the Maven transactions, WITS 2023 and coffee_cost_per_cup.csv as salesrevenue, 2023WITS and coffee_unit_costs.
3. Run 01_setup.sql once, then 02_validation.sql to confirm the checks, then 03 and 04.
