/*
===============================================================================
DDL Script: Create Gold Views (Star Schema)
===============================================================================
Script Purpose:
    This script creates the 'gold' views that represent the final 
    business-ready data model.
    
    The Gold layer is modeled as a Star Schema to optimize for analytical 
    queries and Power BI reporting. It consists of:
    - Dimension Views: 'dim_customers', 'dim_products'
    - Fact View: 'fact_sales'

    These views integrate data from multiple cleansed Silver tables, apply 
    final business logic (e.g., handling mismatched gender data), and generate 
    Surrogate Keys (PK) for the dimensions.

WARNING:
    This script drops existing views if they already exist in the database.
    Because these are views, no physical data is deleted, but the underlying 
    structure will be recreated. 

Author: datahashi96
Date: 2026-11-16
===============================================================================
*/




CREATE VIEW gold.dim_customers AS
	SELECT 
		ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
		ci.cst_id AS customer_id,
		ci.cst_key AS customer_number,
		ci.cst_firstname AS first_name,
		ci.cst_lastname AS last_name,
		la.cntry AS country,
		ci.cst_marital_status AS marital_status,
		CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr -- CRM Master for Gender
			ELSE COALESCE(ca.gen, 'N/A')
		END AS gender,
		ca.bdate AS birthdate,
		ci.cst_create_date AS create_date
	FROM silver.crm_cust_info as ci
	LEFT JOIN silver.erp_cust_az12 as ca
	ON ci.cst_key = ca.cid
	LEFT JOIN silver.erp_loc_a101 as la
	ON ci.cst_key = la.cid

CREATE VIEW gold.dim_products AS
	SELECT 
		ROW_NUMBER() OVER (Order By pn.prd_start_dt,pn.prd_key) AS product_key,
		pn.prd_id as product_id,
		pn.prd_key as product_number,
		pn.prd_nm as product_name,
		pn.cat_id as category_id,
		pc.cat as category,
		pc.subcat as subcategory,
		pc.maintenance,
		pn.prd_cost as cost,
		pn.prd_line product_line,
		pn.prd_start_dt as start_date
	FROM silver.crm_prd_info as pn
	LEFT JOIN silver.erp_px_cat_g1v2 as pc
	ON pn.cat_id = pc.id
	WHERE prd_end_dt IS NULL -- Filter out all historical data. Only want current products

CREATE VIEW gold.facts_sales AS
	SELECT
		sd.sls_ord_num AS order_number,
		pr.product_key,-- replaced prd_key with surrogate key from dim products
		cu.customer_key, -- replaced cust_key with surrogate key from dim customers
		sd.sls_order_dt AS order_date,
		sd.sls_ship_dt AS shipping_date,
		sd.sls_due_dt AS due_date,
		sd.sls_sales AS sales_amount,
		sd.sls_quantity AS quantity,
		sd.sls_price AS price
	FROM silver.crm_sales_details AS sd
	LEFT JOIN gold.dim_products pr
	ON sd.sls_prd_key = pr.product_number
	LEFT JOIN gold.dim_customers cu
	ON sd.sls_cust_id = cu.customer_id
