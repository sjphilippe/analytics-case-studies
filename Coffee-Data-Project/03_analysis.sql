/* =====================================================================
   03_analysis.sql
   Project : Maven Premium Coffee Pilot
   Author  : Shey
   Purpose : Step 3 analysis. One section per business question in the
             brief. Read-only; safe to run at any time.
   Run     : After 01_setup.sql and 02_validation.sql, on SQL Server.
   Source  : coffee_margin (view), coffee_unit_costs, sales_transactions
   Format  : Dollar columns are rounded to cents. Columns ending in _pct
             are percentages (52.3 = 52.3%).
   Ranked  : A "ranked" query is identical to the query above it; only
             the ORDER BY changes, to sort highest to lowest.
   Terms   : "Four coffees" = Brazilian, Columbian Medium Roast,
             Ethiopia and Jamaican Coffee River combined.
             "Comparison coffees" = the four coffees minus Jamaican.
   Note    : Margin = revenue minus estimated bean and packaging cost.
             It excludes labor, rent and overhead, so it is not profit.
   ===================================================================== */


/* ---------------------------------------------------------------------
   Q1  Product performance
   How did Jamaican Coffee River's units, revenue and margin compare
   with Brazilian, Colombian and Ethiopian coffee?
   --------------------------------------------------------------------- */
SELECT coffee_name,
       SUM(transaction_qty)                                                   AS units,
       CAST(SUM(revenue) AS DECIMAL(12,2))                                    AS revenue,
       CAST(SUM(margin)  AS DECIMAL(12,2))                                    AS margin,
       CAST(100.0 * SUM(margin) / SUM(revenue) AS DECIMAL(5,1))               AS margin_pct,
       CAST(SUM(margin) / SUM(transaction_qty) AS DECIMAL(10,2))              AS margin_per_cup,
       CAST(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER () AS DECIMAL(5,1)) AS revenue_share_pct,
       CAST(100.0 * SUM(margin)  / SUM(SUM(margin))  OVER () AS DECIMAL(5,1)) AS margin_share_pct
FROM coffee_margin
GROUP BY coffee_name
ORDER BY margin DESC;


/* ---------------------------------------------------------------------
   Q2  Store performance
   Did Jamaican Coffee River perform differently in Astoria,
   Lower Manhattan and Hell's Kitchen?
   Shares are within each store, across the four coffees (25% = an
   even split).
   --------------------------------------------------------------------- */
SELECT store_location,
       coffee_name,
       SUM(transaction_qty)                                     AS units,
       CAST(SUM(revenue) AS DECIMAL(12,2))                      AS revenue,
       CAST(SUM(margin)  AS DECIMAL(12,2))                      AS margin,
       CAST(100.0 * SUM(margin) / SUM(revenue) AS DECIMAL(5,1)) AS margin_pct,
       CAST(100.0 * SUM(revenue)
            / SUM(SUM(revenue)) OVER (PARTITION BY store_location) AS DECIMAL(5,1)) AS revenue_share_pct,
       CAST(100.0 * SUM(margin)
            / SUM(SUM(margin))  OVER (PARTITION BY store_location) AS DECIMAL(5,1)) AS margin_share_pct
FROM coffee_margin
GROUP BY store_location, coffee_name
ORDER BY store_location, margin DESC;


/* Q2 ranked: same as Q2, sorted by margin % highest to lowest */
SELECT store_location,
       coffee_name,
       SUM(transaction_qty)                                     AS units,
       CAST(SUM(revenue) AS DECIMAL(12,2))                      AS revenue,
       CAST(SUM(margin)  AS DECIMAL(12,2))                      AS margin,
       CAST(100.0 * SUM(margin) / SUM(revenue) AS DECIMAL(5,1)) AS margin_pct,
       CAST(100.0 * SUM(revenue)
            / SUM(SUM(revenue)) OVER (PARTITION BY store_location) AS DECIMAL(5,1)) AS revenue_share_pct,
       CAST(100.0 * SUM(margin)
            / SUM(SUM(margin))  OVER (PARTITION BY store_location) AS DECIMAL(5,1)) AS margin_share_pct
FROM coffee_margin
GROUP BY store_location, coffee_name
ORDER BY margin_pct DESC;


/* ---------------------------------------------------------------------
   Q3a  Demand trend: share of units by month
   Did Jamaican Coffee River's share of coffee sales rise, hold or
   fall from January to June? Kept in month order.
   --------------------------------------------------------------------- */
SELECT DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1) AS sales_month,
       coffee_name,
       SUM(transaction_qty) AS units,
       CAST(100.0 * SUM(transaction_qty)
            / SUM(SUM(transaction_qty)) OVER (
                  PARTITION BY DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1)
              ) AS DECIMAL(5,1)) AS unit_share_pct
FROM coffee_margin
GROUP BY DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1),
         coffee_name
ORDER BY sales_month, coffee_name;


/* ---------------------------------------------------------------------
   Q3b  Shop growth by month (all products, all three stores)
   How much did overall shop activity grow month to month?
   Compare all_store_change_since_jan_pct with
   jamaican_change_since_jan_pct in Q3c.
   --------------------------------------------------------------------- */
WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1) AS sales_month,
           COUNT(*)             AS all_store_transactions,
           SUM(transaction_qty) AS all_store_units
    FROM sales_transactions
    GROUP BY DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1)
)
SELECT sales_month,
       all_store_transactions,
       all_store_units,
       all_store_units - LAG(all_store_units) OVER (ORDER BY sales_month) AS all_store_unit_change,
       CAST(100.0 * (all_store_units - LAG(all_store_units) OVER (ORDER BY sales_month))
            / LAG(all_store_units) OVER (ORDER BY sales_month)
            AS DECIMAL(5,1))                                             AS all_store_unit_change_pct,
       CAST(100.0 * (all_store_units - FIRST_VALUE(all_store_units) OVER (ORDER BY sales_month))
            / FIRST_VALUE(all_store_units) OVER (ORDER BY sales_month)
            AS DECIMAL(5,1))                                             AS all_store_change_since_jan_pct
FROM monthly
ORDER BY sales_month;


/* ---------------------------------------------------------------------
   Q3c  Jamaican growth by month (all three stores)
   Did Jamaican Coffee River grow faster, slower or at the same pace
   as the shop overall?
   --------------------------------------------------------------------- */
WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1) AS sales_month,
           COUNT(*)             AS jamaican_transactions,
           SUM(transaction_qty) AS jamaican_units
    FROM coffee_margin
    WHERE coffee_name = 'Jamaican Coffee River'
    GROUP BY DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1)
)
SELECT sales_month,
       jamaican_transactions,
       jamaican_units,
       jamaican_units - LAG(jamaican_units) OVER (ORDER BY sales_month)  AS jamaican_unit_change,
       CAST(100.0 * (jamaican_units - LAG(jamaican_units) OVER (ORDER BY sales_month))
            / LAG(jamaican_units) OVER (ORDER BY sales_month)
            AS DECIMAL(5,1))                                            AS jamaican_unit_change_pct,
       CAST(100.0 * (jamaican_units - FIRST_VALUE(jamaican_units) OVER (ORDER BY sales_month))
            / FIRST_VALUE(jamaican_units) OVER (ORDER BY sales_month)
            AS DECIMAL(5,1))                                            AS jamaican_change_since_jan_pct
FROM monthly
ORDER BY sales_month;


/* ---------------------------------------------------------------------
   Q4  Profitability: does the price premium cover the extra cost?
   Did Jamaican Coffee River's higher selling price offset its higher
   bean cost? Compared against the average of the comparison coffees,
   size by size. premium_minus_extra_cost below 0 means the price
   premium does NOT cover the extra cost.
   --------------------------------------------------------------------- */
WITH comparison AS (
    SELECT drink_size,
           AVG(unit_price_usd)         AS avg_price,
           AVG(total_cost_usd_per_cup) AS avg_cost
    FROM coffee_unit_costs
    WHERE coffee_name <> 'Jamaican Coffee River'
    GROUP BY drink_size
)
SELECT j.drink_size,
       CAST(j.unit_price_usd                      AS DECIMAL(10,2)) AS jamaican_price,
       CAST(c.avg_price                           AS DECIMAL(10,2)) AS comparison_avg_price,
       CAST(j.unit_price_usd - c.avg_price        AS DECIMAL(10,2)) AS price_premium,
       CAST(j.total_cost_usd_per_cup              AS DECIMAL(10,2)) AS jamaican_cost,
       CAST(c.avg_cost                            AS DECIMAL(10,2)) AS comparison_avg_cost,
       CAST(j.total_cost_usd_per_cup - c.avg_cost AS DECIMAL(10,2)) AS extra_cost,
       CAST((j.unit_price_usd - c.avg_price)
            - (j.total_cost_usd_per_cup - c.avg_cost) AS DECIMAL(10,2)) AS premium_minus_extra_cost
FROM coffee_unit_costs j
JOIN comparison c
    ON j.drink_size = c.drink_size
WHERE j.coffee_name = 'Jamaican Coffee River'
ORDER BY CASE j.drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* Q4 ranked: same as Q4, sorted from the biggest shortfall to the smallest */
WITH comparison AS (
    SELECT drink_size,
           AVG(unit_price_usd)         AS avg_price,
           AVG(total_cost_usd_per_cup) AS avg_cost
    FROM coffee_unit_costs
    WHERE coffee_name <> 'Jamaican Coffee River'
    GROUP BY drink_size
)
SELECT j.drink_size,
       CAST(j.unit_price_usd                      AS DECIMAL(10,2)) AS jamaican_price,
       CAST(c.avg_price                           AS DECIMAL(10,2)) AS comparison_avg_price,
       CAST(j.unit_price_usd - c.avg_price        AS DECIMAL(10,2)) AS price_premium,
       CAST(j.total_cost_usd_per_cup              AS DECIMAL(10,2)) AS jamaican_cost,
       CAST(c.avg_cost                            AS DECIMAL(10,2)) AS comparison_avg_cost,
       CAST(j.total_cost_usd_per_cup - c.avg_cost AS DECIMAL(10,2)) AS extra_cost,
       CAST((j.unit_price_usd - c.avg_price)
            - (j.total_cost_usd_per_cup - c.avg_cost) AS DECIMAL(10,2)) AS premium_minus_extra_cost
FROM coffee_unit_costs j
JOIN comparison c
    ON j.drink_size = c.drink_size
WHERE j.coffee_name = 'Jamaican Coffee River'
ORDER BY premium_minus_extra_cost ASC;


/* ---------------------------------------------------------------------
   Q5  Margin by size
   Which size earns the highest margin per cup, and which contributes
   the most margin in total?
   --------------------------------------------------------------------- */
SELECT coffee_name,
       drink_size,
       SUM(transaction_qty)                                      AS units,
       CAST(SUM(margin) AS DECIMAL(12,2))                        AS total_margin,
       CAST(SUM(margin) / SUM(transaction_qty) AS DECIMAL(10,2)) AS margin_per_cup,
       CAST(100.0 * SUM(margin) / SUM(revenue) AS DECIMAL(5,1))  AS margin_pct
FROM coffee_margin
GROUP BY coffee_name, drink_size
ORDER BY coffee_name,
         CASE drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* Q5 ranked: same as Q5, sorted by margin per cup highest to lowest */
SELECT coffee_name,
       drink_size,
       SUM(transaction_qty)                                      AS units,
       CAST(SUM(margin) AS DECIMAL(12,2))                        AS total_margin,
       CAST(SUM(margin) / SUM(transaction_qty) AS DECIMAL(10,2)) AS margin_per_cup,
       CAST(100.0 * SUM(margin) / SUM(revenue) AS DECIMAL(5,1))  AS margin_pct
FROM coffee_margin
GROUP BY coffee_name, drink_size
ORDER BY margin_per_cup DESC;


/* ---------------------------------------------------------------------
   Q6  Cost of carrying Jamaican Coffee River
   How much margin did the shop give up because Jamaican cups earned
   less than the comparison coffees? Matched size by size.
   margin_given_up = Jamaican units x (comparison margin per cup
   minus Jamaican margin per cup).
   --------------------------------------------------------------------- */
WITH by_size AS (
    SELECT drink_size,
           SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN transaction_qty END) AS jamaican_units,
           SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN margin END)
             / SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN transaction_qty END) AS jamaican_margin_per_cup,
           SUM(CASE WHEN coffee_name <> 'Jamaican Coffee River' THEN margin END)
             / SUM(CASE WHEN coffee_name <> 'Jamaican Coffee River' THEN transaction_qty END) AS comparison_margin_per_cup
    FROM coffee_margin
    GROUP BY drink_size
)
SELECT drink_size,
       jamaican_units,
       CAST(jamaican_margin_per_cup   AS DECIMAL(10,2)) AS jamaican_margin_per_cup,
       CAST(comparison_margin_per_cup AS DECIMAL(10,2)) AS comparison_margin_per_cup,
       CAST(comparison_margin_per_cup - jamaican_margin_per_cup AS DECIMAL(10,2)) AS gap_per_cup,
       CAST(jamaican_units * (comparison_margin_per_cup - jamaican_margin_per_cup)
            AS DECIMAL(12,2)) AS margin_given_up
FROM by_size
ORDER BY CASE drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* Q6 ranked: same as Q6, sorted by margin given up highest to lowest */
WITH by_size AS (
    SELECT drink_size,
           SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN transaction_qty END) AS jamaican_units,
           SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN margin END)
             / SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN transaction_qty END) AS jamaican_margin_per_cup,
           SUM(CASE WHEN coffee_name <> 'Jamaican Coffee River' THEN margin END)
             / SUM(CASE WHEN coffee_name <> 'Jamaican Coffee River' THEN transaction_qty END) AS comparison_margin_per_cup
    FROM coffee_margin
    GROUP BY drink_size
)
SELECT drink_size,
       jamaican_units,
       CAST(jamaican_margin_per_cup   AS DECIMAL(10,2)) AS jamaican_margin_per_cup,
       CAST(comparison_margin_per_cup AS DECIMAL(10,2)) AS comparison_margin_per_cup,
       CAST(comparison_margin_per_cup - jamaican_margin_per_cup AS DECIMAL(10,2)) AS gap_per_cup,
       CAST(jamaican_units * (comparison_margin_per_cup - jamaican_margin_per_cup)
            AS DECIMAL(12,2)) AS margin_given_up
FROM by_size
ORDER BY margin_given_up DESC;


/* Q6 total: one number, total margin given up across all sizes */
WITH by_size AS (
    SELECT drink_size,
           SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN transaction_qty END) AS jamaican_units,
           SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN margin END)
             / SUM(CASE WHEN coffee_name =  'Jamaican Coffee River' THEN transaction_qty END) AS jamaican_margin_per_cup,
           SUM(CASE WHEN coffee_name <> 'Jamaican Coffee River' THEN margin END)
             / SUM(CASE WHEN coffee_name <> 'Jamaican Coffee River' THEN transaction_qty END) AS comparison_margin_per_cup
    FROM coffee_margin
    GROUP BY drink_size
)
SELECT CAST(SUM(jamaican_units * (comparison_margin_per_cup - jamaican_margin_per_cup))
            AS DECIMAL(12,2)) AS total_margin_given_up
FROM by_size;


/* ---------------------------------------------------------------------
   Q7a  Store-by-month share
   Is Jamaican Coffee River gaining share in one store while fading in
   others? jamaican_share_pct = Jamaican units as a percentage of the
   four coffees' units in that store and month (25% = an even split).
   --------------------------------------------------------------------- */
SELECT store_location,
       DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1) AS sales_month,
       SUM(CASE WHEN coffee_name = 'Jamaican Coffee River'
                THEN transaction_qty ELSE 0 END)                         AS jamaican_units,
       SUM(transaction_qty)                                              AS units_all_four_coffees,
       CAST(100.0 * SUM(CASE WHEN coffee_name = 'Jamaican Coffee River'
                             THEN transaction_qty ELSE 0 END)
            / SUM(transaction_qty) AS DECIMAL(5,1))                      AS jamaican_share_pct
FROM coffee_margin
GROUP BY store_location,
         DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1)
ORDER BY store_location, sales_month;


/* ---------------------------------------------------------------------
   Q7b  Shop growth by store and month (all products)
   Is each store growing, and at what pace?
   Compare store_change_since_jan_pct with
   jamaican_change_since_jan_pct in Q7c, same store and month.
   --------------------------------------------------------------------- */
WITH monthly AS (
    SELECT store_location,
           DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1) AS sales_month,
           COUNT(*)             AS store_transactions,
           SUM(transaction_qty) AS store_units
    FROM sales_transactions
    GROUP BY store_location,
             DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1)
)
SELECT store_location,
       sales_month,
       store_transactions,
       store_units,
       store_units - LAG(store_units) OVER (PARTITION BY store_location ORDER BY sales_month) AS store_unit_change,
       CAST(100.0 * (store_units - LAG(store_units) OVER (PARTITION BY store_location ORDER BY sales_month))
            / LAG(store_units) OVER (PARTITION BY store_location ORDER BY sales_month)
            AS DECIMAL(5,1))                                                                  AS store_unit_change_pct,
       CAST(100.0 * (store_units - FIRST_VALUE(store_units) OVER (PARTITION BY store_location ORDER BY sales_month))
            / FIRST_VALUE(store_units) OVER (PARTITION BY store_location ORDER BY sales_month)
            AS DECIMAL(5,1))                                                                  AS store_change_since_jan_pct
FROM monthly
ORDER BY store_location, sales_month;


/* ---------------------------------------------------------------------
   Q7c  Jamaican growth by store and month
   Did Jamaican Coffee River keep pace with growth in each store?
   --------------------------------------------------------------------- */
WITH monthly AS (
    SELECT store_location,
           DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1) AS sales_month,
           COUNT(*)             AS jamaican_transactions,
           SUM(transaction_qty) AS jamaican_units
    FROM coffee_margin
    WHERE coffee_name = 'Jamaican Coffee River'
    GROUP BY store_location,
             DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1)
)
SELECT store_location,
       sales_month,
       jamaican_transactions,
       jamaican_units,
       jamaican_units - LAG(jamaican_units) OVER (PARTITION BY store_location ORDER BY sales_month) AS jamaican_unit_change,
       CAST(100.0 * (jamaican_units - LAG(jamaican_units) OVER (PARTITION BY store_location ORDER BY sales_month))
            / LAG(jamaican_units) OVER (PARTITION BY store_location ORDER BY sales_month)
            AS DECIMAL(5,1))                                                                        AS jamaican_unit_change_pct,
       CAST(100.0 * (jamaican_units - FIRST_VALUE(jamaican_units) OVER (PARTITION BY store_location ORDER BY sales_month))
            / FIRST_VALUE(jamaican_units) OVER (PARTITION BY store_location ORDER BY sales_month)
            AS DECIMAL(5,1))                                                                        AS jamaican_change_since_jan_pct
FROM monthly
ORDER BY store_location, sales_month;


/* ---------------------------------------------------------------------
   Q8  Which sizes do buyers choose?
   Of all the cups each group sold, what percentage were Small,
   Regular and Large? Each group's three rows add up to 100%.
   --------------------------------------------------------------------- */
SELECT CASE WHEN coffee_name = 'Jamaican Coffee River'
            THEN 'Jamaican Coffee River'
            ELSE 'Comparison coffees' END                    AS coffee_group,
       drink_size,
       SUM(transaction_qty)                                  AS cups_sold,
       CAST(100.0 * SUM(transaction_qty)
            / SUM(SUM(transaction_qty)) OVER (
                  PARTITION BY CASE WHEN coffee_name = 'Jamaican Coffee River'
                                    THEN 'Jamaican Coffee River'
                                    ELSE 'Comparison coffees' END
              ) AS DECIMAL(5,1))                             AS pct_of_group_cups
FROM coffee_margin
GROUP BY CASE WHEN coffee_name = 'Jamaican Coffee River'
              THEN 'Jamaican Coffee River'
              ELSE 'Comparison coffees' END,
         drink_size
ORDER BY coffee_group,
         CASE drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;
