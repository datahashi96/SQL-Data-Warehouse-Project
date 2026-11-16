
SQL Data Warehouse Project

Building a modern data warehouse with SQL Server, including ETL processes, data modeling, and analytics.

🎯 Project Overview

This project consolidates data from two source systems (ERP and CRM) provided as CSV files into a unified, business-ready data model. The goal is to enable analytical reporting and informed decision-making.

🏗️ Architecture

The project follows the Medallion Architecture:

· Bronze (Raw): Ingests raw data from the source CSVs without transformations.
· Silver (Cleansed): Cleanses, standardizes, and normalizes the data.
· Gold (Business-Ready): Models the data into a Star Schema (Fact and Dimension tables) for analytical queries.

```mermaid
flowchart LR
    subgraph Sources
        A[CRM CSV]
        B[ERP CSV]
    end

    subgraph Data Warehouse
        C[(Bronze Layer)]
        D[(Silver Layer)]
        E[(Gold Layer)]
    end

    subgraph Consume
        F[Power BI]
    end

    A --> C
    B --> C
    C --> D
    D --> E
    E --> F
```

🛠️ Tech Stack

· Database: Microsoft SQL Server
· Language: T-SQL
· Concepts: ETL, Data Cleansing, Dimensional Modeling (Star Schema), Medallion Architecture.

📂 Repository Structure

· /datasets - Raw CSV files (ERP and CRM).
· /scripts/bronze - DDL and ingestion scripts.
· /scripts/silver - Cleansing and transformation scripts.
· /scripts/gold - Views for the Star Schema.
· /docs - Project requirements and naming conventions.

📊 Data Catalog (Star Schema)

The Gold layer is modeled as a Star Schema to optimize for analytical queries. It consists of one Fact table (fact_sales) and two Dimension tables (dim_customers and dim_products).

```mermaid
erDiagram
    gold.dim_customers ||--o{ gold.fact_sales : "customer_key"
    gold.dim_products ||--o{ gold.fact_sales : "product_key"

    gold.dim_customers {
        int customer_key PK
        int customer_id
        string customer_number
        string first_name
        string last_name
        string country
        string marital_status
        string gender
        date birthdate
    }

    gold.fact_sales {
        string order_number
        int product_key FK
        int customer_key FK
        date order_date
        date shipping_date
        date due_date
        decimal sales_amount
        int quantity
        decimal price
    }

    gold.dim_products {
        int product_key PK
        int product_id
        string product_number
        string product_name
        string category_id
        string category
        string subcategory
        string maintenance
        decimal cost
        string product_line
        date start_date
    }


```mermaid
flowchart LR
    subgraph Sources
        CRM[CRM CSVs]
        ERP[ERP CSVs]
    end

    subgraph Bronze[Bronze Layer]
        B_Cust[crm_cust_info]
        B_Prod[crm_prd_info]
        B_Sales[crm_sales_details]
        B_ErpCust[erp_cust_az12]
        B_ErpLoc[erp_loc_a101]
        B_ErpCat[erp_px_cat_g1v2]
    end

    subgraph Silver[Silver Layer]
        S_Cust[crm_cust_info]
        S_Prod[crm_prd_info]
        S_Sales[crm_sales_details]
        S_ErpCust[erp_cust_az12]
        S_ErpLoc[erp_loc_a101]
        S_ErpCat[erp_px_cat_g1v2]
    end

    subgraph Gold[Gold Layer]
        G_DimCust[dim_customers]
        G_DimProd[dim_products]
        G_Fact[fact_sales]
    end

    CRM --> B_Cust & B_Prod & B_Sales
    ERP --> B_ErpCust & B_ErpLoc & B_ErpCat

    B_Cust --> S_Cust
    B_Prod --> S_Prod
    B_Sales --> S_Sales
    B_ErpCust --> S_ErpCust
    B_ErpLoc --> S_ErpLoc
    B_ErpCat --> S_ErpCat

    S_Cust --> G_DimCust
    S_ErpCust --> G_DimCust
    S_ErpLoc --> G_DimCust

    S_Prod --> G_DimProd
    S_ErpCat --> G_DimProd

    S_Sales --> G_Fact
```

🚀 How to Run

1. Run init_database.sql to create the database and schemas.
2. Run the scripts in the bronze folder to load the raw data.
3. Run the scripts in the silver folder to cleanse the data.
4. Run the scripts in the gold folder to create the analytical views.

📈 Key Insights

(Based on the Gold layer analysis)

· Product Performance: The Mountain and Road product lines represent the highest volume of sales, indicating a strong market fit for outdoor and standard cycling gear.
· Customer Demographics: The customer base is heavily concentrated in the United States and Australia, presenting an opportunity for targeted regional marketing.
· Data Quality Impact: Implementing the SCD Type 1 logic in the Silver layer successfully resolved 100% of the NULL and invalid date anomalies from the source systems, ensuring reliable reporting.
