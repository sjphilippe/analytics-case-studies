# Data Dictionary: Maven Premium Coffee Pilot

The three tables in the SQL Server database. Types are as stored after cleanup. How these tables join into the coffee_margin view is in the Source-to-Target Mapping.

## sales_transactions

Maven point-of-sale data. 149,116 rows, one per item line on a transaction, January 1 to June 30, 2023.

| Column | Type | Description |
| --- | --- | --- |
| transaction_id | INT, not null | Unique ID of the line |
| transaction_date | DATE | Date of the sale |
| transaction_time | TIME | Time of the sale |
| transaction_qty | TINYINT | Number of items on the line |
| store_id | TINYINT | Store number |
| store_location | NVARCHAR(50) | Astoria, Hell's Kitchen or Lower Manhattan |
| product_id | TINYINT | Product number |
| unit_price | DECIMAL(10,2) | Selling price per item, in USD |
| product_category | NVARCHAR(50) | Broad product group, such as Coffee, Tea or Bakery |
| product_type | NVARCHAR(50) | Narrower product group |
| product_detail | NVARCHAR(50) | Product and size, such as Jamaican Coffee River Rg. Join key to coffee_unit_costs |

## wits_2023

US imports of green coffee in 2023, one row per exporting country plus a World total.

| Column | Type | Description |
| --- | --- | --- |
| Reporter | NVARCHAR(50), not null | Importing country (United States) |
| TradeFlow | NVARCHAR(50), not null | Direction of trade (Import) |
| ProductCode | VARCHAR(10) | Trade product code (090111, green coffee) |
| Product_Description | NVARCHAR(50), not null | Product name for the code |
| Year | SMALLINT, not null | Trade year (2023) |
| Partner | NVARCHAR(50), not null | Exporting country. Matches origin_country in coffee_unit_costs |
| Trade_Value_1000USD | FLOAT, not null | Value of imports from the country, in thousands of USD |
| Quantity | FLOAT, not null | Weight of imports from the country, in kg |
| Quantity_Unit | NVARCHAR(50), not null | Unit of Quantity (Kg) |

## coffee_unit_costs

Estimated cost per cup. 12 rows, one per coffee and size, loaded from coffee_cost_per_cup.csv.

| Column | Type | Description | Source or formula |
| --- | --- | --- | --- |
| product_detail | NVARCHAR(50), not null | Coffee and size. Join key to sales_transactions | Maven product_detail |
| coffee_name | NVARCHAR(50), not null | Coffee name without the size | Maven product_detail, size removed |
| origin_country | NVARCHAR(50), not null | Country the beans come from | Mapped from coffee_name |
| drink_size | NVARCHAR(50), not null | Sm, Rg or Lg | Maven product_detail |
| cup_size_oz | TINYINT, not null | Cup volume, in fl oz | Set by size: 8, 12, 16 |
| grams_roasted_per_cup | FLOAT, not null | Roasted coffee brewed into one cup, in grams | Set by size: 13, 19.5, 26 |
| grams_green_per_cup | FLOAT, not null | Green coffee needed to produce the roasted grams | grams_roasted_per_cup ÷ 0.82 |
| import_value_usd_per_kg | DECIMAL(10,4) | Average 2023 import price for the origin, in USD per kg | wits_2023: Trade_Value_1000USD × 1,000 ÷ Quantity |
| procurement_multiplier | TINYINT, not null | Roaster markup over the import price | Set at 3 |
| bean_cost_usd_per_cup | DECIMAL(10,6) | Estimated coffee cost in one cup, in USD | grams_green_per_cup ÷ 1,000 × import_value_usd_per_kg × procurement_multiplier |
| consumables_usd_per_cup | DECIMAL(10,2) | Cup, lid and sleeve cost, in USD | Set by size: 0.18, 0.21, 0.24 |
| total_cost_usd_per_cup | DECIMAL(10,6) | Bean plus consumables cost, in USD | bean_cost_usd_per_cup + consumables_usd_per_cup |
| unit_price_usd | DECIMAL(10,2) | Selling price, in USD | Maven unit_price |
