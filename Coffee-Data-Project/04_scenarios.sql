/* =====================================================================
   04_scenarios.sql
   Project : Maven Premium Coffee Pilot
   Author  : Shey
   Purpose : Step 4 scenarios. Tests two ways to close Jamaican Coffee
             River's margin gap: charging more (A) and paying less for
             the beans (B), a sensitivity check on the 3x roaster
             markup assumption (C), and both levers together (D).
             Read-only; nothing here changes data.
   Run     : After 01_setup.sql, on SQL Server.
   Source  : coffee_margin (view), coffee_unit_costs

   How to read these results
   -------------------------
   The data covers January to June 2023, which has already happened.
   Every scenario replays those SAME six months with one thing changed
   (a higher price, a cheaper roaster). Nothing here forecasts future
   months.

   actual_...   = what really happened, January to June 2023.
   new_...      = the same six months, re-run with the scenario change.
   margin_added = new minus actual. Always the last margin column.

   Other coffees = Brazilian, Columbian Medium Roast and Ethiopia.
   other_coffees_avg_margin_per_cup = the average margin those three
   coffees earn on ONE cup of the same size (matches Q4 in
   03_analysis.sql).
   vs_others_before / vs_others_after = Jamaican's margin per cup
   minus that average, before and after the change. Negative means
   Jamaican earns LESS per cup than the other coffees; positive means
   it now earns MORE.

   Dollar columns are rounded to cents. Columns ending in _pct are
   percentages (52.3 = 52.3%).
   ===================================================================== */


/* =====================================================================
   A. CHARGE MORE
   Jamaican's menu price goes up $0.25 or $0.50 at every size. Costs do
   not change, so every cent of the increase becomes extra margin on
   each cup sold.

   The unknown: would customers still have bought as many cups at the
   higher price? Instead of guessing, A2 and A3 show both ends:
     - the margin if every customer still bought it, and
     - how many cups the shop could lose before the increase stops
       paying off (the break-even point).
   ===================================================================== */


/* ---------------------------------------------------------------------
   A1  Price increase: one cup
   Question: how much closer does each increase bring one Jamaican cup
   to what the other coffees earn per cup?

   Columns
     current_price / new_price       Jamaican's menu price, before/after
     current / new_margin_per_cup    what one Jamaican cup earns
     other_coffees_avg_margin_per_cup  what one cup of the other
                                     coffees earns, same size (average)
     vs_others_before / vs_others_after  Jamaican's margin per cup
                                     minus that average; negative =
                                     behind, positive = ahead
   --------------------------------------------------------------------- */
WITH other_coffees AS (
    SELECT drink_size,
           AVG(unit_price_usd - total_cost_usd_per_cup) AS avg_margin_per_cup
    FROM coffee_unit_costs
    WHERE coffee_name <> 'Jamaican Coffee River'
    GROUP BY drink_size
)
SELECT s.price_increase,
       j.drink_size,
       CAST(j.unit_price_usd AS DECIMAL(10,2))                                          AS current_price,
       CAST(j.unit_price_usd + s.price_increase AS DECIMAL(10,2))                       AS new_price,
       CAST(j.unit_price_usd - j.total_cost_usd_per_cup AS DECIMAL(10,2))                AS current_margin_per_cup,
       CAST(j.unit_price_usd + s.price_increase - j.total_cost_usd_per_cup
            AS DECIMAL(10,2))                                                           AS new_margin_per_cup,
       CAST(o.avg_margin_per_cup AS DECIMAL(10,2))                                      AS other_coffees_avg_margin_per_cup,
       CAST((j.unit_price_usd - j.total_cost_usd_per_cup) - o.avg_margin_per_cup
            AS DECIMAL(10,2))                                                           AS vs_others_before,
       CAST((j.unit_price_usd + s.price_increase - j.total_cost_usd_per_cup) - o.avg_margin_per_cup
            AS DECIMAL(10,2))                                                           AS vs_others_after
FROM coffee_unit_costs j
JOIN other_coffees o
    ON j.drink_size = o.drink_size
CROSS JOIN (VALUES (0.25), (0.50)) AS s(price_increase)
WHERE j.coffee_name = 'Jamaican Coffee River'
ORDER BY s.price_increase,
         CASE j.drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* ---------------------------------------------------------------------
   A2  Price increase: six months, by size
   Question: if Jamaican had cost more from January to June, how much
   more margin would it have earned, and how many customers could the
   shop have lost before the increase stopped being worth it?

   Columns
     cups_sold          Jamaican cups actually sold, Jan-Jun
     actual_margin      margin Jamaican actually earned, Jan-Jun
     new_margin         margin at the higher price IF every customer
                        still bought it (same cups_sold). Best case.
     margin_added       new_margin minus actual_margin
     cup_loss_cushion   the break-even point. Each cup now earns more,
                        so fewer cups are needed to match
                        actual_margin. This is how many cups could be
                        lost and the shop still earns what it actually
                        earned. Lose more than this and the increase
                        made things worse.
     cup_loss_cushion_pct  the same, as a share of cups_sold

   Example: a Small earning $1.43 earns $1.68 after +$0.25. About 85
   cups at $1.68 earn the same as 100 cups at $1.43, so about 15% of
   Small cups could be lost before the increase stops paying off.
   --------------------------------------------------------------------- */
WITH jamaican AS (
    SELECT drink_size,
           SUM(transaction_qty) AS cups_sold,
           SUM(margin)          AS actual_margin
    FROM coffee_margin
    WHERE coffee_name = 'Jamaican Coffee River'
    GROUP BY drink_size
)
SELECT s.price_increase,
       j.drink_size,
       j.cups_sold,
       CAST(j.actual_margin AS DECIMAL(12,2))                                     AS actual_margin,
       CAST(j.actual_margin + j.cups_sold * s.price_increase AS DECIMAL(12,2))    AS new_margin,
       CAST(j.cups_sold * s.price_increase AS DECIMAL(12,2))                      AS margin_added,
       CAST(FLOOR(j.cups_sold * (j.cups_sold * s.price_increase)
                  / (j.actual_margin + j.cups_sold * s.price_increase)) AS INT)   AS cup_loss_cushion,
       CAST(100.0 * (j.cups_sold * s.price_increase)
            / (j.actual_margin + j.cups_sold * s.price_increase) AS DECIMAL(5,1)) AS cup_loss_cushion_pct
FROM jamaican j
CROSS JOIN (VALUES (0.25), (0.50)) AS s(price_increase)
ORDER BY s.price_increase,
         CASE j.drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* ---------------------------------------------------------------------
   A3  Price increase: six months, all sizes combined
   Same question and columns as A2, for Jamaican as a whole.
   --------------------------------------------------------------------- */
WITH jamaican AS (
    SELECT SUM(transaction_qty) AS cups_sold,
           SUM(margin)          AS actual_margin
    FROM coffee_margin
    WHERE coffee_name = 'Jamaican Coffee River'
)
SELECT s.price_increase,
       j.cups_sold,
       CAST(j.actual_margin AS DECIMAL(12,2))                                     AS actual_margin,
       CAST(j.actual_margin + j.cups_sold * s.price_increase AS DECIMAL(12,2))    AS new_margin,
       CAST(j.cups_sold * s.price_increase AS DECIMAL(12,2))                      AS margin_added,
       CAST(FLOOR(j.cups_sold * (j.cups_sold * s.price_increase)
                  / (j.actual_margin + j.cups_sold * s.price_increase)) AS INT)   AS cup_loss_cushion,
       CAST(100.0 * (j.cups_sold * s.price_increase)
            / (j.actual_margin + j.cups_sold * s.price_increase) AS DECIMAL(5,1)) AS cup_loss_cushion_pct
FROM jamaican j
CROSS JOIN (VALUES (0.25), (0.50)) AS s(price_increase)
ORDER BY s.price_increase;


/* =====================================================================
   B. PAY LESS FOR THE BEANS
   Jamaican alone moves to a cheaper roaster. The base case assumes the
   roaster charges 3x the import price of the green beans; these
   scenarios test 2.5x and 2x.

   new bean cost = current bean cost / 3 x new multiplier

   The menu price does not change, so customers see no difference and
   sales volume is not affected. Every cent saved on beans becomes
   margin. The other coffees are unchanged.
   ===================================================================== */


/* ---------------------------------------------------------------------
   B1  Cheaper roaster: one cup
   Question: how much closer does each roaster deal bring one Jamaican
   cup to what the other coffees earn per cup?

   Columns
     current / new_bean_cost         Jamaican bean cost per cup
     current / new_margin_per_cup    what one Jamaican cup earns
     margin_added_per_cup            the bean saving per cup
     other_coffees_avg_margin_per_cup  what one cup of the other
                                     coffees earns, same size (average)
     vs_others_before / vs_others_after  Jamaican's margin per cup
                                     minus that average; negative =
                                     behind, positive = ahead
   --------------------------------------------------------------------- */
WITH other_coffees AS (
    SELECT drink_size,
           AVG(unit_price_usd - total_cost_usd_per_cup) AS avg_margin_per_cup
    FROM coffee_unit_costs
    WHERE coffee_name <> 'Jamaican Coffee River'
    GROUP BY drink_size
),
jamaican AS (
    SELECT s.new_multiplier,
           c.drink_size,
           c.unit_price_usd,
           c.consumables_usd_per_cup,
           c.bean_cost_usd_per_cup                                               AS current_bean_cost,
           c.bean_cost_usd_per_cup / c.procurement_multiplier * s.new_multiplier AS new_bean_cost
    FROM coffee_unit_costs c
    CROSS JOIN (VALUES (2.5), (2.0)) AS s(new_multiplier)
    WHERE c.coffee_name = 'Jamaican Coffee River'
)
SELECT j.new_multiplier,
       j.drink_size,
       CAST(j.current_bean_cost AS DECIMAL(10,2))                                              AS current_bean_cost,
       CAST(j.new_bean_cost AS DECIMAL(10,2))                                                  AS new_bean_cost,
       CAST(j.unit_price_usd - j.current_bean_cost - j.consumables_usd_per_cup AS DECIMAL(10,2)) AS current_margin_per_cup,
       CAST(j.unit_price_usd - j.new_bean_cost - j.consumables_usd_per_cup AS DECIMAL(10,2))     AS new_margin_per_cup,
       CAST(j.current_bean_cost - j.new_bean_cost AS DECIMAL(10,2))                            AS margin_added_per_cup,
       CAST(o.avg_margin_per_cup AS DECIMAL(10,2))                                             AS other_coffees_avg_margin_per_cup,
       CAST((j.unit_price_usd - j.current_bean_cost - j.consumables_usd_per_cup)
            - o.avg_margin_per_cup AS DECIMAL(10,2))                                          AS vs_others_before,
       CAST((j.unit_price_usd - j.new_bean_cost - j.consumables_usd_per_cup)
            - o.avg_margin_per_cup AS DECIMAL(10,2))                                          AS vs_others_after
FROM jamaican j
JOIN other_coffees o
    ON j.drink_size = o.drink_size
ORDER BY j.new_multiplier DESC,
         CASE j.drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* ---------------------------------------------------------------------
   B2  Cheaper roaster: six months, by size
   Question: if Jamaican's beans had come from a cheaper roaster from
   January to June, how much more margin would it have earned?
   Sales are the real ones, since the menu price did not change.

   Columns
     cups_sold       Jamaican cups actually sold, Jan-Jun
     actual_margin   margin Jamaican actually earned, Jan-Jun
     new_margin      margin on the same cups with cheaper beans
     margin_added    new_margin minus actual_margin
   --------------------------------------------------------------------- */
WITH jamaican AS (
    SELECT drink_size,
           SUM(transaction_qty) AS cups_sold,
           SUM(margin)          AS actual_margin
    FROM coffee_margin
    WHERE coffee_name = 'Jamaican Coffee River'
    GROUP BY drink_size
),
bean_saving AS (
    SELECT s.new_multiplier,
           c.drink_size,
           c.bean_cost_usd_per_cup
           - c.bean_cost_usd_per_cup / c.procurement_multiplier * s.new_multiplier AS saving_per_cup
    FROM coffee_unit_costs c
    CROSS JOIN (VALUES (2.5), (2.0)) AS s(new_multiplier)
    WHERE c.coffee_name = 'Jamaican Coffee River'
)
SELECT b.new_multiplier,
       j.drink_size,
       j.cups_sold,
       CAST(j.actual_margin AS DECIMAL(12,2))                                 AS actual_margin,
       CAST(j.actual_margin + j.cups_sold * b.saving_per_cup AS DECIMAL(12,2)) AS new_margin,
       CAST(j.cups_sold * b.saving_per_cup AS DECIMAL(12,2))                  AS margin_added
FROM jamaican j
JOIN bean_saving b
    ON j.drink_size = b.drink_size
ORDER BY b.new_multiplier DESC,
         CASE j.drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* ---------------------------------------------------------------------
   B3  Cheaper roaster: six months, all sizes combined
   Same question and columns as B2, for Jamaican as a whole.
   --------------------------------------------------------------------- */
WITH jamaican AS (
    SELECT drink_size,
           SUM(transaction_qty) AS cups_sold,
           SUM(margin)          AS actual_margin
    FROM coffee_margin
    WHERE coffee_name = 'Jamaican Coffee River'
    GROUP BY drink_size
),
bean_saving AS (
    SELECT s.new_multiplier,
           c.drink_size,
           c.bean_cost_usd_per_cup
           - c.bean_cost_usd_per_cup / c.procurement_multiplier * s.new_multiplier AS saving_per_cup
    FROM coffee_unit_costs c
    CROSS JOIN (VALUES (2.5), (2.0)) AS s(new_multiplier)
    WHERE c.coffee_name = 'Jamaican Coffee River'
)
SELECT b.new_multiplier,
       SUM(j.cups_sold)                                                            AS cups_sold,
       CAST(SUM(j.actual_margin) AS DECIMAL(12,2))                                 AS actual_margin,
       CAST(SUM(j.actual_margin + j.cups_sold * b.saving_per_cup) AS DECIMAL(12,2)) AS new_margin,
       CAST(SUM(j.cups_sold * b.saving_per_cup) AS DECIMAL(12,2))                  AS margin_added
FROM jamaican j
JOIN bean_saving b
    ON j.drink_size = b.drink_size
GROUP BY b.new_multiplier
ORDER BY b.new_multiplier DESC;


/* =====================================================================
   C. SENSITIVITY CHECK
   The 3x roaster markup is an estimate, not a known price. If it is
   wrong, every coffee's bean cost is wrong, not just Jamaican's. This
   check recalculates ALL four coffees at 2x (beans a third cheaper)
   and asks: does Jamaican still earn the lowest margin?

   If yes, the main finding does not depend on the 3x guess.

   Why the coffees do not all move the same amount: the markup only
   multiplies bean cost. A coffee whose beans take a bigger share of
   its price gains more when the markup drops. Jamaican's beans are
   the most expensive, so it gains the most. The question is whether
   it gains enough to catch up.
   ===================================================================== */


/* ---------------------------------------------------------------------
   C1  Every coffee at 3x and 2x
   Question: how does each coffee's margin change at 2x, and does the
   ranking change?

   Columns
     revenue                   six-month revenue (does not change)
     margin_pct_at_3x          margin as % of revenue, base case
     margin_pct_at_2x          margin as % of revenue, beans 1/3 cheaper
     pct_points_gained         2x minus 3x. Larger for coffees whose
                               beans take a bigger share of revenue.
     rank_at_3x / rank_at_2x   1 = highest margin %. If Jamaican is
                               last in both, the finding holds.
   --------------------------------------------------------------------- */
WITH by_coffee AS (
    SELECT m.coffee_name,
           SUM(m.revenue)                                  AS revenue,
           SUM(m.margin)                                   AS margin_at_3x,
           SUM(m.transaction_qty
               * (m.unit_price
                  - (c.bean_cost_usd_per_cup / c.procurement_multiplier * 2
                     + c.consumables_usd_per_cup)))         AS margin_at_2x
    FROM coffee_margin m
    JOIN coffee_unit_costs c
        ON m.coffee_name = c.coffee_name
       AND m.drink_size  = c.drink_size
    GROUP BY m.coffee_name
)
SELECT coffee_name,
       CAST(revenue AS DECIMAL(12,2))                                           AS revenue,
       CAST(100.0 * margin_at_3x / revenue AS DECIMAL(5,1))                     AS margin_pct_at_3x,
       CAST(100.0 * margin_at_2x / revenue AS DECIMAL(5,1))                     AS margin_pct_at_2x,
       CAST(100.0 * (margin_at_2x - margin_at_3x) / revenue AS DECIMAL(5,1))    AS pct_points_gained,
       RANK() OVER (ORDER BY margin_at_3x / revenue DESC)                       AS rank_at_3x,
       RANK() OVER (ORDER BY margin_at_2x / revenue DESC)                       AS rank_at_2x
FROM by_coffee
ORDER BY margin_at_3x / revenue DESC;


/* ---------------------------------------------------------------------
   C2  Jamaican's gap to each other coffee, at 3x and 2x
   Question: how far behind is Jamaican at each markup, and how much of
   that gap does a lower markup close?

   Columns
     compared_to   the other coffee
     gap_at_3x     that coffee's margin % minus Jamaican's, base case
     gap_at_2x     the same at 2x
     gap_closed    gap_at_3x minus gap_at_2x

   Gaps are in percentage points. If gap_at_2x is still above 0 for
   every coffee, Jamaican stays last even with much cheaper beans.
   --------------------------------------------------------------------- */
WITH by_coffee AS (
    SELECT m.coffee_name,
           100.0 * SUM(m.margin) / SUM(m.revenue) AS pct_at_3x,
           100.0 * SUM(m.transaction_qty
                       * (m.unit_price
                          - (c.bean_cost_usd_per_cup / c.procurement_multiplier * 2
                             + c.consumables_usd_per_cup)))
                 / SUM(m.revenue)                 AS pct_at_2x
    FROM coffee_margin m
    JOIN coffee_unit_costs c
        ON m.coffee_name = c.coffee_name
       AND m.drink_size  = c.drink_size
    GROUP BY m.coffee_name
)
SELECT o.coffee_name                                                                   AS compared_to,
       CAST(o.pct_at_3x - j.pct_at_3x AS DECIMAL(5,1))                                 AS gap_at_3x,
       CAST(o.pct_at_2x - j.pct_at_2x AS DECIMAL(5,1))                                 AS gap_at_2x,
       CAST((o.pct_at_3x - j.pct_at_3x) - (o.pct_at_2x - j.pct_at_2x) AS DECIMAL(5,1)) AS gap_closed
FROM by_coffee o
CROSS JOIN by_coffee j
WHERE j.coffee_name = 'Jamaican Coffee River'
  AND o.coffee_name <> 'Jamaican Coffee River'
ORDER BY gap_at_3x DESC;


/* =====================================================================
   D. BOTH LEVERS TOGETHER
   Jamaican's price goes up $0.25 AND it moves to a roaster at 2x.
   The two stack: the price increase adds to each cup's revenue, the
   roaster deal takes away from each cup's cost.

   The levels live in one place (the params CTE in each query), so
   another combination is a one-line change.

   The price increase still carries the risk of losing customers; the
   roaster deal does not. D2 and D3 therefore show two cushions:
     - against what actually happened (both levers together), and
     - against the roaster deal alone, which is the real test of
       whether ADDING the price increase is worth it.
   ===================================================================== */


/* ---------------------------------------------------------------------
   D1  Both levers: one cup
   Question: with both changes, where does one Jamaican cup land
   against what the other coffees earn per cup?

   Columns
     price_increase / new_multiplier the scenario: price added per cup
                                     and the roaster markup tested
     current / new_price             Jamaican's menu price
     current / new_bean_cost         Jamaican bean cost per cup
     current / new_margin_per_cup    what one Jamaican cup earns
     margin_added_per_cup            price increase + bean saving
     other_coffees_avg_margin_per_cup  what one cup of the other
                                     coffees earns, same size (average)
     vs_others_before / vs_others_after  Jamaican's margin per cup
                                     minus that average; negative =
                                     behind, positive = ahead
   --------------------------------------------------------------------- */
WITH params AS (
    SELECT CAST(0.25 AS DECIMAL(10,2)) AS price_increase,
           CAST(2.0  AS DECIMAL(3,1))  AS new_multiplier
),
other_coffees AS (
    SELECT drink_size,
           AVG(unit_price_usd - total_cost_usd_per_cup) AS avg_margin_per_cup
    FROM coffee_unit_costs
    WHERE coffee_name <> 'Jamaican Coffee River'
    GROUP BY drink_size
),
jamaican AS (
    SELECT c.drink_size,
           c.unit_price_usd                                                      AS current_price,
           c.unit_price_usd + p.price_increase                                   AS new_price,
           c.bean_cost_usd_per_cup                                               AS current_bean_cost,
           c.bean_cost_usd_per_cup / c.procurement_multiplier * p.new_multiplier AS new_bean_cost,
           c.consumables_usd_per_cup
    FROM coffee_unit_costs c
    CROSS JOIN params p
    WHERE c.coffee_name = 'Jamaican Coffee River'
)
SELECT p.price_increase,
       p.new_multiplier,
       j.drink_size,
       CAST(j.current_price AS DECIMAL(10,2))                                                  AS current_price,
       CAST(j.new_price AS DECIMAL(10,2))                                                      AS new_price,
       CAST(j.current_bean_cost AS DECIMAL(10,2))                                              AS current_bean_cost,
       CAST(j.new_bean_cost AS DECIMAL(10,2))                                                  AS new_bean_cost,
       CAST(j.current_price - j.current_bean_cost - j.consumables_usd_per_cup AS DECIMAL(10,2)) AS current_margin_per_cup,
       CAST(j.new_price - j.new_bean_cost - j.consumables_usd_per_cup AS DECIMAL(10,2))         AS new_margin_per_cup,
       CAST((j.new_price - j.new_bean_cost) - (j.current_price - j.current_bean_cost)
            AS DECIMAL(10,2))                                                                  AS margin_added_per_cup,
       CAST(o.avg_margin_per_cup AS DECIMAL(10,2))                                             AS other_coffees_avg_margin_per_cup,
       CAST((j.current_price - j.current_bean_cost - j.consumables_usd_per_cup)
            - o.avg_margin_per_cup AS DECIMAL(10,2))                                          AS vs_others_before,
       CAST((j.new_price - j.new_bean_cost - j.consumables_usd_per_cup)
            - o.avg_margin_per_cup AS DECIMAL(10,2))                                          AS vs_others_after
FROM jamaican j
JOIN other_coffees o
    ON j.drink_size = o.drink_size
CROSS JOIN params p
ORDER BY CASE j.drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* ---------------------------------------------------------------------
   D2  Both levers: six months, by size
   Question: if Jamaican had cost $0.25 more AND come from a 2x roaster
   from January to June, how much more margin would it have earned, and
   how many customers could the shop have lost?

   Columns
     price_increase / new_multiplier  the scenario being tested
     cups_sold              Jamaican cups actually sold, Jan-Jun
     actual_margin          margin Jamaican actually earned, Jan-Jun
     new_margin             margin with both changes IF every customer
                            still bought it. Best case.
     margin_added           new_margin minus actual_margin
     cup_loss_cushion       cups that could be lost and the shop still
                            earns actual_margin (break-even vs today)
     cup_loss_cushion_pct   the same, as a share of cups_sold
     cushion_vs_roaster_only_pct  the share of cups that could be lost
                            and still beat doing the roaster deal ALONE.
                            Lose more than this and the price increase
                            cost money, even if the total still beats
                            actual_margin.
   --------------------------------------------------------------------- */
WITH params AS (
    SELECT CAST(0.25 AS DECIMAL(10,2)) AS price_increase,
           CAST(2.0  AS DECIMAL(3,1))  AS new_multiplier
),
jamaican AS (
    SELECT drink_size,
           SUM(transaction_qty) AS cups_sold,
           SUM(margin)          AS actual_margin
    FROM coffee_margin
    WHERE coffee_name = 'Jamaican Coffee River'
    GROUP BY drink_size
),
added_per_cup AS (
    SELECT c.drink_size,
           p.price_increase,
           c.bean_cost_usd_per_cup
           - c.bean_cost_usd_per_cup / c.procurement_multiplier * p.new_multiplier AS bean_saving
    FROM coffee_unit_costs c
    CROSS JOIN params p
    WHERE c.coffee_name = 'Jamaican Coffee River'
),
totals AS (
    SELECT j.drink_size,
           j.cups_sold,
           j.actual_margin,
           j.cups_sold * a.price_increase                         AS price_part,
           j.cups_sold * (a.price_increase + a.bean_saving)       AS margin_added
    FROM jamaican j
    JOIN added_per_cup a
        ON j.drink_size = a.drink_size
)
SELECT p.price_increase,
       p.new_multiplier,
       t.drink_size,
       t.cups_sold,
       CAST(t.actual_margin AS DECIMAL(12,2))                                       AS actual_margin,
       CAST(t.actual_margin + t.margin_added AS DECIMAL(12,2))                              AS new_margin,
       CAST(t.margin_added AS DECIMAL(12,2))                                                AS margin_added,
       CAST(FLOOR(t.cups_sold * t.margin_added / (t.actual_margin + t.margin_added)) AS INT) AS cup_loss_cushion,
       CAST(100.0 * t.margin_added / (t.actual_margin + t.margin_added) AS DECIMAL(5,1))    AS cup_loss_cushion_pct,
       CAST(100.0 * t.price_part / (t.actual_margin + t.margin_added) AS DECIMAL(5,1))      AS cushion_vs_roaster_only_pct
FROM totals t
CROSS JOIN params p
ORDER BY CASE t.drink_size WHEN 'Sm' THEN 1 WHEN 'Rg' THEN 2 ELSE 3 END;


/* ---------------------------------------------------------------------
   D3  Both levers: six months, all sizes combined
   Same question and columns as D2, for Jamaican as a whole.
   --------------------------------------------------------------------- */
WITH params AS (
    SELECT CAST(0.25 AS DECIMAL(10,2)) AS price_increase,
           CAST(2.0  AS DECIMAL(3,1))  AS new_multiplier
),
jamaican AS (
    SELECT drink_size,
           SUM(transaction_qty) AS cups_sold,
           SUM(margin)          AS actual_margin
    FROM coffee_margin
    WHERE coffee_name = 'Jamaican Coffee River'
    GROUP BY drink_size
),
added_per_cup AS (
    SELECT c.drink_size,
           p.price_increase,
           c.bean_cost_usd_per_cup
           - c.bean_cost_usd_per_cup / c.procurement_multiplier * p.new_multiplier AS bean_saving
    FROM coffee_unit_costs c
    CROSS JOIN params p
    WHERE c.coffee_name = 'Jamaican Coffee River'
),
totals AS (
    SELECT SUM(j.cups_sold)                                        AS cups_sold,
           SUM(j.actual_margin)                                    AS actual_margin,
           SUM(j.cups_sold * a.price_increase)                     AS price_part,
           SUM(j.cups_sold * (a.price_increase + a.bean_saving))   AS margin_added
    FROM jamaican j
    JOIN added_per_cup a
        ON j.drink_size = a.drink_size
)
SELECT p.price_increase,
       p.new_multiplier,
       t.cups_sold,
       CAST(t.actual_margin AS DECIMAL(12,2))                                       AS actual_margin,
       CAST(t.actual_margin + t.margin_added AS DECIMAL(12,2))                              AS new_margin,
       CAST(t.margin_added AS DECIMAL(12,2))                                                AS margin_added,
       CAST(FLOOR(t.cups_sold * t.margin_added / (t.actual_margin + t.margin_added)) AS INT) AS cup_loss_cushion,
       CAST(100.0 * t.margin_added / (t.actual_margin + t.margin_added) AS DECIMAL(5,1))    AS cup_loss_cushion_pct,
       CAST(100.0 * t.price_part / (t.actual_margin + t.margin_added) AS DECIMAL(5,1))      AS cushion_vs_roaster_only_pct
FROM totals t
CROSS JOIN params p;
