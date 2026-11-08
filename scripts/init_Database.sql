/*
===========================================
Create Database and Schemas
===========================================
Script Purpose:
	This script creates a new database named 'DataWarehouse' after checking if it already exists.
	If the database exists, it is dropped and recreated. Additionally, the script sets up 3 schemas
	within the database. 'bronze', 'silver', 'gold'


Warning:
	Running this script will drop the entire 'DataWarehouse' database if it exists.
	All data in the database with be permanently deleted. Proceed with caution and
	ensure you have proper backups before running this script

*/

USE master; -- need to be on assistant database
-- master to create other Databases

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

CREATE DATABASE DataWarehouse;

USE DataWarehouse;
GO
--using medallion architecture
--need to create schemas for each layer

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO;
