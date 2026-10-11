/* =====================================================================
   02_validation.sql
   Project : Maven Premium Coffee Pilot
   Author  : Shey
   Purpose : Read-only data quality checks. Safe to run at any time;
             nothing in this script changes data.
   Run     : After 01_setup.sql, on SQL Server.
   Tables  : sales_transactions, coffee_unit_costs, wits_2023,
             coffee_margin (view)
   Check numbers match the Validation Results table in the
   Source-to-Target Mapping.
   ===================================================================== */


/* ---------------------------------------------------------------------
   Check 1: Row count and date range
   Expected: 149,116 rows; first date 2023-01-01; last date 2023-06-30
   --------------------------------------------------------------------- */
SELECT COUNT(*)              AS total_rows,
       MIN(transaction_date) AS first_date,
       MAX(transaction_date) AS last_date
FROM sales_transactions;


/* ---------------------------------------------------------------------
   Check 2: Days with sales
   Expected: 181 (every day from January 1 to June 30, 2023)
   --------------------------------------------------------------------- */
SELECT COUNT(DISTINCT transaction_date) AS days_with_sales
FROM sales_transactions;


/* ---------------------------------------------------------------------
   Check 3: Nulls in key columns
   Expected: 0 in every column
   --------------------------------------------------------------------- */
SELECT
    SUM(CASE WHEN product_detail  IS NULL THEN 1 ELSE 0 END) AS null_product,
    SUM(CASE WHEN transaction_qty IS NULL THEN 1 ELSE 0 END) AS null_qty,
    SUM(CASE WHEN unit_price      IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN store_location  IS NULL THEN 1 ELSE 0 END) AS null_store
FROM sales_transactions;


/* ---------------------------------------------------------------------
   Check 4: Join keys match
   Expected: 12 rows, each with matching_sales_rows above 0.
   A 0 means that product_detail in the cost table has no exact match
   in the sales data (spelling or spacing difference).
   --------------------------------------------------------------------- */
SELECT c.product_detail,
       COUNT(s.product_detail) AS matching_sales_rows
FROM coffee_unit_costs c
LEFT JOIN sales_transactions s
    ON s.product_detail = c.product_detail
GROUP BY c.product_detail
ORDER BY c.product_detail;


/* ---------------------------------------------------------------------
   Check 5: Prices constant and match the cost table
   Expected: 12 rows; min_price, max_price and cost_table_price equal
   on every row
   --------------------------------------------------------------------- */
SELECT s.product_detail,
       MIN(s.unit_price) AS min_price,
       MAX(s.unit_price) AS max_price,
       c.unit_price_usd  AS cost_table_price
FROM sales_transactions s
JOIN coffee_unit_costs c
    ON s.product_detail = c.product_detail
GROUP BY s.product_detail, c.unit_price_usd
ORDER BY s.product_detail;


/* ---------------------------------------------------------------------
   Check 6: Units by coffee and size
   Expected: 12 rows totaling 51,416 units.
   Jamaican Coffee River: Lg 4,395; Rg 4,018; Sm 4,018
   (Rg and Sm are genuinely equal; see issue 10)
   --------------------------------------------------------------------- */
SELECT c.coffee_name,
       c.drink_size,
       SUM(s.transaction_qty) AS units_sold
FROM sales_transactions s
JOIN coffee_unit_costs c
    ON s.product_detail = c.product_detail
GROUP BY c.coffee_name, c.drink_size
ORDER BY c.coffee_name, c.drink_size;


/* ---------------------------------------------------------------------
   Check 7: WITS import values match the cost table
   Expected: 4 rows; values equal within rounding (under 0.1%).
   Brazil 4.01, Colombia 5.36, Ethiopia 7.30, Jamaica 17.74
   Trade value is in thousands of USD, so it is multiplied by 1,000.
   WITS lists Ethiopia as 'Ethiopia(excludes Eritrea)' (issue 5).
   --------------------------------------------------------------------- */
SELECT c.origin_country,
       CAST(w.Trade_Value_1000USD AS FLOAT) * 1000 / w.Quantity AS wits_usd_per_kg,
       c.import_value_usd_per_kg                               AS cost_table_usd_per_kg
FROM wits_2023 w
JOIN (SELECT DISTINCT origin_country, import_value_usd_per_kg
      FROM coffee_unit_costs) c
    ON CASE
           WHEN LTRIM(RTRIM(w.Partner)) = 'Ethiopia(excludes Eritrea)' THEN 'Ethiopia'
           ELSE LTRIM(RTRIM(w.Partner))
       END = c.origin_country
WHERE w.ProductCode = '090111'
ORDER BY c.origin_country;


/* ---------------------------------------------------------------------
   Check 8: View reconciles to sources
   Expected: 33,536 rows; 51,416 units; $146,562.25 revenue
   Spot check: Jamaican Coffee River revenue = $38,781.15
   --------------------------------------------------------------------- */
SELECT COUNT(*)             AS view_rows,
       SUM(transaction_qty) AS units,
       SUM(revenue)         AS revenue
FROM coffee_margin;

SELECT SUM(revenue) AS jamaican_revenue
FROM coffee_margin
WHERE coffee_name = 'Jamaican Coffee River';
