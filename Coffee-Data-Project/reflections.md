# My Take — Maven Premium Coffee Pilot

Oct 5, 2026 · @Shey

A personal look back at the project: why I picked it, what it was like building it with an AI agent, what the data couldn't tell me, and the judgment calls behind the numbers.

## Why I chose this project

I spent five years supporting restaurant owners on their point-of-sale and retail systems. A coffee shop's transaction data is something I know from the client side: what the fields mean, how menus and sizes are set up, and what owners actually ask of their reports.

I wanted a project that ends in a business decision, not just a set of charts. Most portfolio projects with this dataset stop at "best-selling product" and "busiest hour." Pairing the sales data with real import prices let me ask a question an operations director would: is the premium coffee worth what it costs to carry? That also let me work the way I would as a business systems analyst: writing a requirements brief, mapping and validating the data, and making a recommendation.

Overall I enjoyed working on this dataset and creating my own story to go along with it. Working with Claude helped tremendously in some areas, but lagged in others. From this project I came away knowing how to prompt Claude better to reduce wasted time. I would like to try this project again with a more robust data set that includes some of the missing gaps described below. Additionally, I would have preferred to work with a strictly tea dataset as I don't drink coffee, but a coffee shop was close enough.

## How I worked with an AI agent

I used Claude as a coding and documentation assistant. The split of work looked like this:

| I owned | The agent drafted |
| --- | --- |
| The business question and the four-step plan | SQL scripts for setup, validation, analysis and scenarios |
| Choosing the data sources and the cost approach | First drafts of the brief, mapping, dictionary, and findings |
| Running every query in SQL Server and checking the output | Placeholder charts and calculations to check results against |
| Deciding what stayed in scope and what was cut | Explanations of results and trade-offs when I asked |
| The final recommendation |  |

The agent was fastest at the parts that are tedious to do: writing long SQL scripts, cross-checking numbers between documents, and keeping the issues log in sync. The judgment calls, such as using real import data instead of an invented roaster table, or stopping at four scenarios, came from me pushing back on what it proposed. The Change Record lists every change and who raised it.

## Where the agent fell short

Most of my agent corrections fell into a handful of patterns that I had to repeatedly adjust for such as over-engineering, scope creep, various inconsistencies and queries that were hard for a person to read and a lack of comments to name a few. I can see how the frequency of these issues could add up in a work setting and eat into the token budget.

## What I'd do differently

1. **Set the rules before the first query.** Put my conventions in the project instructions so they apply to every chat: simple queries a person can read at a glance, plain-English column names, and so on.
2. **Ask for the plan before the code.** A short outline of the columns and what each one means is quicker to correct than a finished script.
3. **Give feedback in one batch.** One message listing every fix for a script costs less than five rounds of single fixes.
4. **Ask the agent to check its own work** against those conventions before handing anything over.
5. **Keep a scope list in the brief** and point to it whenever a new idea comes up.

## Where the dataset fell short

Besides some mild clean up upon loading into SQL server, the sales data is clean and complete for what it records. However, the data only shows sales, not costs (beans, rent, labor) or customer behavior. That set the limits of the project, so some of the data had to be estimated from assumptions or an outside source (WITS).

Other things I noticed in the dataset was that each coffee sold within about 5% of the others' cup totals, and Jamaican's share barely moved from month to month. It seems unlikely in a real setting that sales over this period of time would skew toward such a clean average. That pattern suggests the data was generated rather than recorded.

Where the data fell short and why:

| Gap | Why it mattered | What would have helped |
| --- | --- | --- |
| No cost data at all | Margin had to be estimated from import prices and assumptions | Supplier invoices or the shop's actual bean costs |
| Prices never changed | No way to measure how customers react to a price increase, so the price scenarios assume sales hold | A price change during the period, or a test in one store |
| No customer IDs | Couldn't tell whether Jamaican buyers are regulars or one-off customers | Loyalty or card data linking repeat purchases |
| Only six months | Can't see seasonality or whether growth continued | A full year or more |
| Jamaican sold from day one | No before-and-after to see whether it pulled sales from other coffees | A launch date inside the data |

## Assumptions I made and why

The biggest judgment call was the bean cost. I used real 2023 import prices with a single 3× roaster markup instead of building a detailed roaster cost table, which would have been invented numbers dressed up as precision. To make sure the result didn't hinge on that guess, I reran everything at 2×, and Jamaican still came out last. The full list of assumptions is in the Business Brief.
