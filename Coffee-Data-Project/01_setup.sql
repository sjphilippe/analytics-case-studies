/* =====================================================================
   01_setup.sql
   Project : Maven Premium Coffee Pilot
   Author  : Shey
   Purpose : One-time setup. Renames tables, fixes data types found
             during validation, and creates the coffee_margin view.
   Run     : Once, top to bottom, on SQL Server (2016 SP1 or later).
             Each step is written so a rerun does no harm.
   Tables  : sales_transactions, coffee_unit_costs, wits_2023
   Issue numbers refer to the Data Issues Log.
   ===================================================================== */


/* ---------------------------------------------------------------------
   Step 1: Table names
   Gives the imported tables clearer names that need no quotes.
   Guarded so the rename only runs if the old name still exists.
   --------------------------------------------------------------------- */
IF OBJECT_ID('dbo.[2023WITS]') IS NOT NULL
    EXEC sp_rename 'dbo.[2023WITS]', 'wits_2023';

IF OBJECT_ID('dbo.salesrevenue') IS NOT NULL
    EXEC sp_rename 'dbo.salesrevenue', 'sales_transactions';
GO


/* ---------------------------------------------------------------------
   Step 2: WITS product code
   Issue 2: ProductCode 090111 was imported as the date 2009-01-11.
   --------------------------------------------------------------------- */
ALTER TABLE wits_2023 ALTER COLUMN ProductCode VARCHAR(10);
GO

UPDATE wits_2023
SET ProductCode = '090111';
GO


/* ---------------------------------------------------------------------
   Step 3: Exact decimal types
   Issue 11: prices were stored as single-precision float
             (2.20 read as 2.20000004768372).
   Issue 12: import values had the same float storage.
   --------------------------------------------------------------------- */
ALTER TABLE sales_transactions ALTER COLUMN unit_price              DECIMAL(10,2);
ALTER TABLE coffee_unit_costs  ALTER COLUMN unit_price_usd          DECIMAL(10,2);
ALTER TABLE coffee_unit_costs  ALTER COLUMN import_value_usd_per_kg DECIMAL(10,4);
ALTER TABLE coffee_unit_costs  ALTER COLUMN bean_cost_usd_per_cup   DECIMAL(10,6);
ALTER TABLE coffee_unit_costs  ALTER COLUMN total_cost_usd_per_cup  DECIMAL(10,6);
GO


/* ---------------------------------------------------------------------
   Step 3b: Consumables column
   Issue 13: consumables_usd_per_cup was imported as a time value, which
   cannot be converted directly to a number. The column is rebuilt as
   DECIMAL(10,2). Guarded so it only runs while the column is still
   a time type; dynamic SQL lets the new column be used in the same batch.
   --------------------------------------------------------------------- */
IF EXISTS (SELECT 1
           FROM INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_NAME  = 'coffee_unit_costs'
             AND COLUMN_NAME = 'consumables_usd_per_cup'
             AND DATA_TYPE   = 'time')
BEGIN
    EXEC('ALTER TABLE coffee_unit_costs ADD consumables_fixed DECIMAL(10,2)');
    EXEC('UPDATE coffee_unit_costs
          SET consumables_fixed = CASE drink_size WHEN ''Sm'' THEN 0.18
                                                  WHEN ''Rg'' THEN 0.21
                                                  WHEN ''Lg'' THEN 0.24 END');
    EXEC('ALTER TABLE coffee_unit_costs DROP COLUMN consumables_usd_per_cup');
    EXEC sp_rename 'coffee_unit_costs.consumables_fixed', 'consumables_usd_per_cup', 'COLUMN';
END
GO


/* ---------------------------------------------------------------------
   Step 4: Analysis view
   Joins each sale to its estimated cost per cup and calculates
   revenue, cost and margin per line. The inner join keeps only the
   12 products in coffee_unit_costs (four coffees x three sizes).
   Field-by-field rules are documented in the Source-to-Target Mapping.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW coffee_margin AS
SELECT
    s.transaction_id,
    s.transaction_date,
    s.transaction_time,
    s.store_location,
    c.coffee_name,
    c.origin_country,
    c.drink_size,
    s.transaction_qty,
    s.unit_price,
    c.total_cost_usd_per_cup,
    s.transaction_qty * s.unit_price                               AS revenue,
    s.transaction_qty * c.total_cost_usd_per_cup                   AS total_cost,
    s.transaction_qty * (s.unit_price - c.total_cost_usd_per_cup)  AS margin
FROM sales_transactions s
JOIN coffee_unit_costs c
    ON s.product_detail = c.product_detail;
GO

/* After running, execute 02_validation.sql to confirm the results. */
