# Data Issues Log: Maven Premium Coffee Pilot

Data, import and cost-model problems found during the project, and how each was resolved.

| ID | Area | Issue | Fix | Status |
| --- | --- | --- | --- | --- |
| 1 | Import | WITS column names contained spaces (Trade Value 1000USD, Quantity Unit), so every query needed quotes | Renamed with underscores on import | Fixed |
| 2 | Import | WITS product code 090111 was read as the date 2009-01-11 | Changed the column to text, then reset it to '090111' | Fixed |
| 3 | Import | WITS trade values were stored at slightly lower precision than the source (Brazil 1317530 vs 1317529.97) | Accepted: changes the price per kg by under one cent | Accepted |
| 4 | Transformation | WITS trade values are in thousands of USD, so dividing by kg directly gave prices 1,000 times too small | Multiply by 1,000 before dividing by quantity | Handled in query |
| 5 | Transformation | WITS lists Ethiopia as "Ethiopia(excludes Eritrea)," which doesn't match "Ethiopia" in the cost table | Mapped to "Ethiopia" in the join | Handled in query |
| 6 | Transformation | Some WITS country names had extra spaces (for example " World"), so they didn't match exactly when joined | Trimmed spaces from country names in the join | Handled in query |
| 7 | Cost model | The sales data has no bean costs, so they were estimated from import prices. The first version applied the green bean price to roasted grams, understating cost by about 18%, since beans lose weight in roasting | Added grams of green coffee per cup (roasted grams ÷ 0.82) | Fixed |
| 8 | Cost model | The sales data has no packaging costs, so they were estimated. The first version used a flat $0.25 for every size | Set by size: Small $0.18, Regular $0.21, Large $0.24 | Fixed |
| 9 | Cost model | Estimating bean cost from the raw import price left out shipping, roasting and the roaster's margin, so margins were unrealistically high | Added a 3× roaster markup; 2.5× and 2× tested in the scenarios | Fixed |
| 10 | Sales data | Jamaican Small and Regular both totaled exactly 4,018 units, which looked like a duplication error | Checked by size: both genuinely total 4,018, from different row counts (2,630 and 2,594) | Accepted |
| 11 | Import | Prices were stored as approximate decimals, so 2.20 read as 2.20000004768372 | Changed to exact decimal types | Fixed |
| 12 | Cost model | Cost table import prices were rounded to the cent (Brazil 4.01 vs WITS 4.0095) | Accepted: difference is under 0.1%; column changed to four decimal places | Accepted |
| 13 | Import | The packaging cost column loaded as a time type, so values like 0.18 displayed as times instead of prices | Rebuilt the column as a price. Margins were unaffected, since total cost is stored separately | Fixed |
| 14 | Import | Sales dates and times loaded as the wrong data types | Converted to DATE and TIME | Fixed |

## Status key

| Status | Meaning |
| --- | --- |
| Fixed | Corrected in the source table or file |
| Handled in query | Source left as is; corrected by a rule in the SQL |
| Accepted | Known and left in place because the effect is too small to matter |
