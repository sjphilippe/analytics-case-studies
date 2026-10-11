# Source-to-Target Mapping: Maven Premium Coffee Pilot

Where every field in the coffee_margin view comes from. Column definitions for the source tables are in the Data Dictionary.

## Sources and join

| Table | Role | One row per | In the view |
| --- | --- | --- | --- |
| sales_transactions | Sales volume, revenue and selling price | Item on a transaction | Yes |
| coffee_unit_costs | Estimated cost per cup | Coffee and size | Yes |
| wits_2023 | Source of the import prices in coffee_unit_costs | Exporting country | No, used to check import prices |

**Join:** sales_transactions INNER JOIN coffee_unit_costs ON product_detail. Only the 12 coffee products in the cost table are kept, which reduces 149,116 sales rows to 33,536.

## coffee_margin view

**Copied as is from sales_transactions:** transaction_id, transaction_date, transaction_time, store_location, transaction_qty, unit_price.

| Target field | Meaning | Source | Rule |
| --- | --- | --- | --- |
| coffee_name | Coffee, without size | coffee_unit_costs.coffee_name | Looked up on product_detail |
| origin_country | Country the beans come from | coffee_unit_costs.origin_country | Looked up on product_detail |
| drink_size | Small, Regular or Large | coffee_unit_costs.drink_size | Looked up on product_detail |
| total_cost_usd_per_cup | Estimated bean and packaging cost per cup | coffee_unit_costs.total_cost_usd_per_cup | Looked up on product_detail |
| revenue | Sales dollars on the line | sales_transactions | transaction_qty × unit_price |
| total_cost | Estimated cost of the cups sold | Both tables | transaction_qty × total_cost_usd_per_cup |
| margin | Revenue minus estimated bean and packaging cost | Both tables | transaction_qty × (unit_price − total_cost_usd_per_cup) |

## WITS into coffee_unit_costs

Import prices come from WITS, filtered to product code 090111 (green coffee), year 2023, importer United States.

| Target field | Source | Rule |
| --- | --- | --- |
| origin_country | wits_2023.Partner | Spaces trimmed; "Ethiopia(excludes Eritrea)" mapped to "Ethiopia" |
| import_value_usd_per_kg | wits_2023.Trade_Value_1000USD, Quantity | Trade value × 1,000 ÷ quantity in kg, stored to four decimal places |

## Validation results

Every check passed. The queries are in 02_validation.sql, in the same order as this table.

| Check | Expected | Result |
| --- | --- | --- |
| Row count and date range | Full dataset, Jan 1 to Jun 30, 2023 | 149,116 rows, Jan 1 to Jun 30, 2023 |
| Days with sales | 181 | 181 |
| Nulls in key columns | 0 | 0 in product_detail, transaction_qty, unit_price, store_location |
| Join keys match | All 12 products found in sales | 12 of 12, with 2,594 to 3,013 rows each |
| Prices constant and match cost table | One price per product, equal to the cost table | Matched for all 12 |
| Units by coffee and size | Totals reconcile | 51,416 units across the four coffees |
| WITS import prices match cost table | Equal within rounding | Matched for all four origins, within 0.1% |
| View reconciles to sources | 33,536 rows, 51,416 units | 33,536 rows, 51,416 units, $146,562.25 revenue |
