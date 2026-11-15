/*
===============================================================================
Data Quality & Integrity Checks
===============================================================================
Script Purpose:
    This script contains a series of ad-hoc queries used to explore, profile, 
    and validate the data at various stages of the pipeline (primarily between 
    Bronze and Silver).
    
    The goal is to identify anomalies, ensure referential integrity, and catch 
    bad data before it flows into the Gold layer and breaks business reports.

Checks Performed:
    - Primary Key Uniqueness (Checking for duplicates).
    - NULL value checks on mandatory fields.
    - Invalid Date checks (e.g., future dates, end dates before start dates).
    - Negative values or zero checks (e.g., product costs).
    - Out-of-bounds checks (e.g., unrealistic birthdates).
    - Referential integrity (Ensuring foreign keys exist in dimension tables).

Author: datahashi96
Date: 2026-11-15
===============================================================================
*/

SELECT
	cst_id,
	COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 or cst_id IS NULL


-- check for unwanted spaces
--expectation no result, do for all column names
SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname)

-- check for data standardisation and consistency
-- for low cardinality columns (only a few values: e.g. gender/marital status)
--
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info
 

--Table 2 bronze.crm_prd_info checks
--1. check primary key for nulls and duplicates

SELECT 
	prd_id,
	count(*)
from silver.crm_prd_info
GROUP by PRD_id
HAVING count(*) > 1 or PRD_id IS NULL
-- no output, so primary key is valid. no nulls or duplicates


SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

select prd_cost
from silver.crm_prd_info
where prd_cost < 0 or prd_cost IS NULL

SELECT DISTINCT PRD_LINE
from silver.crm_prd_info

SELECT *
from silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

SELECT *
FROM silver.crm_prd_info

--table 3
-- check for invalid dates
-- integer column. check no. of characters should be 8
-- check for nulls, negatives and boundary -- 2050
SELECT NULLIF(sls_due_dt,0)
FROM silver.crm_sales_details
WHERE sls_due_dt <= 0 
OR LEN(sls_due_dt) != 8 
OR sls_due_dt > 20500101 
OR sls_due_dt < 19400101

SELECT *
from silver.crm_sales_details
WHERE sls_order_dt > sls_due_dt

SELECT
	sls_sales,
	sls_quantity,
	sls_price
from silver.crm_sales_details
WHERE sls_sales != (sls_price) * (sls_quantity)
OR sls_sales IS NULL or sls_quantity IS NULL or sls_price is NULL
OR sls_sales <= 0 or sls_quantity <= 0 or sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price
 -- discuss with expert in business to discuss best way to fix problem
 -- dont assume

 -- After speaking to expert in sales team. 
	-- If sales are negative, zero or null. derive it using quantity and price
	-- if price is zero or null. calculate using sales and quantiity
	-- if price is negative, convert to positive value

	SELECT DISTINCT
		sls_sales as old_sls_sales,
		sls_quantity,
		sls_price as old_sls_price,
		sls_sales
		sls_price
	from bronze.crm_sales_details

SELECT * FROM silver.crm_sales_details

SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' -- very old customers exist!
or bdate > GETDATE()

SELECT distinct gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	ELSE 'N/A'
END as gen2
from silver.erp_cust_az12

select * from silver.erp_cust_az12

select distinct cntry,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	WHEN TRIM(cntry) = '' or cntry IS NULL THEN 'N/A'
	ELSE TRIM(cntry)
END as cntry1
from silver.erp_loc_a101
ORDER BY CNTRY

SELECT * FROM silver.erp_loc_a101

SELECT distinct maintenance
FROM bronze.erp_px_cat_g1v2
