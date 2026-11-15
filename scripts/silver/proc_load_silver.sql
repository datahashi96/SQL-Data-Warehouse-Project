/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process 
    to populate the 'silver' schema tables from the 'bronze' schema.
    
    Actions Performed:
    - Truncates Silver tables to ensure idempotency (safe to re-run).
    - Inserts transformed and cleansed data from Bronze into Silver tables.
    - Applies data quality rules (deduplication, handling NULLs, 
      standardizing categorical values like 'M'/'F').
    - Fixes data anomalies (e.g., ensuring product end dates align with 
      the next version's start date).

    Error Handling & Logging:
    - Implemented using TRY...CATCH blocks.
    - Prints step-by-step progress and the execution time for each table.

Author: datahashi96
Date: 2026-11-15
===============================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME;
    
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

        -- ==========================================
        -- TABLE 1: CRM CUSTOMER INFO
        -- ==========================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        
        PRINT '>> Inserting Data Into: silver.crm_cust_info';
   INSERT INTO silver.crm_cust_info (
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date) 
	SELECT
	cst_id,
	cst_key,
	TRIM(cst_firstname) as cst_firstname,
	TRIM(cst_lastname) as cst_lastname,
	CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
		WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		ELSE 'N/A'
	END cst_marital_status,
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'N/A'
	END cst_gndr,
	cst_create_date
	FROM (
		SELECT
		*,
		ROW_NUMBER() OVER (Partition By cst_id Order By cst_create_date desc) as flag_last
		FROM bronze.crm_cust_info
		WHERE CST_id IS NOT NULL
	)t WHERE flag_last = 1



        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ==========================================
        -- TABLE 2: CRM PRODUCT INFO
        -- ==========================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        
        PRINT '>> Inserting Data Into: silver.crm_prd_info';
       INSERT INTO silver.crm_prd_info (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
		)
	SELECT
		prd_id,
		REPLACE(SUBSTRING(prd_key,1,5),'-', '_') AS cat_id, -- transform so can join later
		SUBSTRING(prd_key, 7, len(prd_key))  AS prd_key,
		prd_nm,
		ISNULL(prd_cost,0) as prd_cost,
		CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
			WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
			WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			ELSE 'N/A'
		END as prd_line,
		CAST(prd_start_dt AS DATE) as prd_start_dt,
		CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
	FROM bronze.crm_prd_info

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ==========================================
        -- TABLE 3: CRM SALES DETAILS
        -- ==========================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        
        PRINT '>> Inserting Data Into: silver.crm_sales_details';
	INSERT INTO silver.crm_sales_details (
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
	SELECT
		sls_ord_num,
		sls_prd_key, --subquery where this column NOT IN (table to be joined), no row output, all good. 
		sls_cust_id, --subquery where this column NOT IN (table to be joined), no row output, all good. 
		CASE WHEN sls_order_dt = 0 or LEN(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR) as DATE) -- convert to varchar first, then date. SQL server limitation
		END as sls_order_dt,
		CASE WHEN sls_ship_dt = 0 or LEN(sls_ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR) as DATE) -- convert to varchar first, then date. SQL server limitation
		END as sls_ship_dt,
		CASE WHEN sls_due_dt = 0 or LEN(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR) as DATE) -- convert to varchar first, then date. SQL server limitation
		END as sls_due_dt,
			CASE WHEN sls_sales <= 0 OR sls_sales IS NULL or sls_sales != sls_quantity * ABS(sls_price) 
			THEN sls_quantity * ABS(sls_price)
			ELSE sls_sales
		END as sls_sales,
		sls_quantity,
		CASE WHEN sls_price <= 0 or sls_price IS NULL 
			THEN sls_sales/NULLIF(sls_quantity,0)
			ELSE sls_price
		END as sls_price
	FROM bronze.crm_sales_details

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ==========================================
        -- TABLE 4: ERP CUSTOMER AZ12
        -- ==========================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        
        PRINT '>> Inserting Data Into: silver.erp_cust_az12';
 INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
	SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4, len(cid))
		ELSE cid
	END Cid,
		CASE WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END as bdate,
		CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
		WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
		ELSE 'N/A'
	END as gen
	FROM bronze.erp_cust_az12

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ==========================================
        -- TABLE 5: ERP LOC A101
        -- ==========================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        
        PRINT '>> Inserting Data Into: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101 (cid, cntry)
	SELECT
		REPLACE(cid,'-','') cid,
		CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
		WHEN TRIM(cntry) = '' or cntry IS NULL THEN 'N/A'
		ELSE TRIM(cntry)
	END as cntry
	FROM bronze.erp_loc_a101

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ==========================================
        -- TABLE 6: ERP PX CAT G1V2
        -- ==========================================
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        
        PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
 	INSERT INTO silver.erp_px_cat_g1v2 (
		id,
		cat,
		subcat,
		maintenance)
	select *
	from bronze.erp_px_cat_g1v2

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        -- ==========================================
        -- TOTAL DURATION
        -- ==========================================
        SET @end_time = GETDATE();
        PRINT '================================================';
        PRINT '>> Total Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';

    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;
