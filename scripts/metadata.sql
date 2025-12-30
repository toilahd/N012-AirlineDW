USE master;
GO

-- Drop database nếu tồn tại
ALTER DATABASE metadata_airlines SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE IF EXISTS metadata_airlines;
GO

-- Tạo database mới
CREATE DATABASE metadata_airlines;
GO

USE metadata_airlines;
GO

-- ===============================
-- 1. DATA STRUCTURE METADATA TABLES
-- ===============================

-- Table: ds_data_store
DROP TABLE IF EXISTS ds_data_store;
GO
CREATE TABLE dbo.ds_data_store (
    store_id INT IDENTITY(1,1) PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);
GO

-- Table: ds_table_type
DROP TABLE IF EXISTS ds_table_type;
GO
CREATE TABLE dbo.ds_table_type (
    type_id INT IDENTITY(1,1) PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL
);
GO

-- Table: ds_table
DROP TABLE IF EXISTS ds_table;
GO
CREATE TABLE dbo.ds_table (
    table_id INT IDENTITY(1,1) PRIMARY KEY,
    store_id INT NOT NULL,
    table_type_id INT NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    description TEXT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (store_id) REFERENCES ds_data_store(store_id),
    FOREIGN KEY (table_type_id) REFERENCES ds_table_type(type_id)
);
GO

-- Table: ds_column
DROP TABLE IF EXISTS ds_column;
GO
CREATE TABLE dbo.ds_column (
    column_id INT IDENTITY(1,1) PRIMARY KEY,
    table_id INT NOT NULL,
    column_name VARCHAR(100) NOT NULL,
    data_type VARCHAR(50) NOT NULL,
    is_null BIT NOT NULL,
    is_PK BIT NOT NULL,
    is_FK BIT NOT NULL,
    FOREIGN KEY (table_id) REFERENCES ds_table(table_id)
);
GO

-- ===============================
-- 2. DATAFLOW TABLE (ETL Metadata)
-- ===============================

DROP TABLE IF EXISTS dataflow;
GO
CREATE TABLE dbo.dataflow (
    flow_id INT IDENTITY(1,1) PRIMARY KEY,
    flow_name VARCHAR(100) NOT NULL,
    source_table_id INT NOT NULL,
    destination_table_id INT NOT NULL,
    LSET DATETIME NULL,
    CET DATETIME NULL,
    status VARCHAR(50) NULL,
    FOREIGN KEY (source_table_id) REFERENCES ds_table(table_id),
    FOREIGN KEY (destination_table_id) REFERENCES ds_table(table_id)
);

GO
-- ====================================================
-- STEP 1: REFERENCE DATA (STORES & TYPES)
-- ====================================================

-- 1.1 Insert Data Stores
IF NOT EXISTS (SELECT 1 FROM dbo.ds_data_store WHERE store_name = 'Source')
    INSERT INTO dbo.ds_data_store (store_name, description) VALUES ('Source', 'Original raw data from CSV');

IF NOT EXISTS (SELECT 1 FROM dbo.ds_data_store WHERE store_name = 'Stage')
    INSERT INTO dbo.ds_data_store (store_name, description) VALUES ('Stage', 'Stage layer for initial cleansing');

IF NOT EXISTS (SELECT 1 FROM dbo.ds_data_store WHERE store_name = 'NDS_AIRLINES')
    INSERT INTO dbo.ds_data_store (store_name, description) VALUES ('NDS_AIRLINES', 'Normalized Data Store (3NF)');

IF NOT EXISTS (SELECT 1 FROM dbo.ds_data_store WHERE store_name = 'DDS_AIRLINES')
    INSERT INTO dbo.ds_data_store (store_name, description) VALUES ('DDS_AIRLINES', 'Dimensional Data Store (Star Schema)');

-- 1.2 Insert Table Types
IF NOT EXISTS (SELECT 1 FROM dbo.ds_table_type WHERE type_name = 'Raw')
    INSERT INTO dbo.ds_table_type (type_name, description) VALUES ('Raw', 'Raw tables in Source');

IF NOT EXISTS (SELECT 1 FROM dbo.ds_table_type WHERE type_name = 'Stage')
    INSERT INTO dbo.ds_table_type (type_name, description) VALUES ('Stage', 'Stage tables');

IF NOT EXISTS (SELECT 1 FROM dbo.ds_table_type WHERE type_name = 'Normal Table')
    INSERT INTO dbo.ds_table_type (type_name, description) VALUES ('Normal Table', 'Standard normalized table');

IF NOT EXISTS (SELECT 1 FROM dbo.ds_table_type WHERE type_name = 'Dimension')
    INSERT INTO dbo.ds_table_type (type_name, description) VALUES ('Dimension', 'Dimension table for analysis');

IF NOT EXISTS (SELECT 1 FROM dbo.ds_table_type WHERE type_name = 'Fact')
    INSERT INTO dbo.ds_table_type (type_name, description) VALUES ('Fact', 'Fact table containing measurements');
GO

-- ====================================================
-- STEP 2: REGISTER SOURCE & STAGE TABLES
-- ====================================================
DECLARE @Store_Source INT, @Store_Stage INT;
DECLARE @Type_Raw INT, @Type_Stage INT;

-- Get IDs
SELECT @Store_Source = store_id FROM ds_data_store WHERE store_name = 'Source';
SELECT @Store_Stage  = store_id FROM ds_data_store WHERE store_name = 'Stage';
SELECT @Type_Raw     = type_id FROM ds_table_type WHERE type_name = 'Raw';
SELECT @Type_Stage   = type_id FROM ds_table_type WHERE type_name = 'Stage';

-- 2.1 Insert Source Tables
IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'airlines_source')
    INSERT INTO ds_table (store_id, table_type_id, table_name, description) VALUES (@Store_Source, @Type_Raw, 'airlines_source', 'Raw airlines data');

IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'airports_source')
    INSERT INTO ds_table (store_id, table_type_id, table_name, description) VALUES (@Store_Source, @Type_Raw, 'airports_source', 'Raw airports data');

IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'flights_source')
    INSERT INTO ds_table (store_id, table_type_id, table_name, description) VALUES (@Store_Source, @Type_Raw, 'flights_source', 'Raw flights data');

-- 2.2 Insert Stage Tables
IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'airlines_stage')
    INSERT INTO ds_table (store_id, table_type_id, table_name, description) VALUES (@Store_Stage, @Type_Stage, 'airlines_stage', 'Stage airlines data');

IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'airports_stage')
    INSERT INTO ds_table (store_id, table_type_id, table_name, description) VALUES (@Store_Stage, @Type_Stage, 'airports_stage', 'Stage airports data');

IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'flights_stage')
    INSERT INTO ds_table (store_id, table_type_id, table_name, description) VALUES (@Store_Stage, @Type_Stage, 'flights_stage', 'Stage flights data');
GO

-- ====================================================
-- STEP 3: REGISTER NDS & DDS TABLES
-- ====================================================
DECLARE @NDS_ID INT, @DDS_ID INT;
DECLARE @Type_Norm INT, @Type_Dim INT, @Type_Fact INT;

-- Get IDs
SELECT @NDS_ID = store_id FROM ds_data_store WHERE store_name = 'NDS_AIRLINES';
SELECT @DDS_ID = store_id FROM ds_data_store WHERE store_name = 'DDS_AIRLINES';
SELECT @Type_Norm = type_id FROM ds_table_type WHERE type_name = 'Normal Table';
SELECT @Type_Dim  = type_id FROM ds_table_type WHERE type_name = 'Dimension';
SELECT @Type_Fact = type_id FROM ds_table_type WHERE type_name = 'Fact';

-- 3.1 NDS Tables
IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'airline' AND store_id = @NDS_ID)
    INSERT INTO ds_table (store_id, table_type_id, table_name) VALUES (@NDS_ID, @Type_Norm, 'airline');

IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'airport' AND store_id = @NDS_ID)
    INSERT INTO ds_table (store_id, table_type_id, table_name) VALUES (@NDS_ID, @Type_Norm, 'airport');

IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'flight' AND store_id = @NDS_ID)
    INSERT INTO ds_table (store_id, table_type_id, table_name) VALUES (@NDS_ID, @Type_Norm, 'flight');

-- 3.2 DDS Tables
IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'Dim_Airline' AND store_id = @DDS_ID)
    INSERT INTO ds_table (store_id, table_type_id, table_name) VALUES (@DDS_ID, @Type_Dim, 'Dim_Airline');

IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'Dim_Airport' AND store_id = @DDS_ID)
    INSERT INTO ds_table (store_id, table_type_id, table_name) VALUES (@DDS_ID, @Type_Dim, 'Dim_Airport');

IF NOT EXISTS (SELECT 1 FROM ds_table WHERE table_name = 'Fact_Flight' AND store_id = @DDS_ID)
    INSERT INTO ds_table (store_id, table_type_id, table_name) VALUES (@DDS_ID, @Type_Fact, 'Fact_Flight');
GO

-- ====================================================
-- STEP 4: REGISTER DATAFLOWS (Set LSET = 2020-01-01)
-- ====================================================

-- A. SOURCE -> STAGE
DECLARE @Src_Air_Raw INT, @Src_Air_Stg INT;
DECLARE @Src_Port_Raw INT, @Src_Port_Stg INT;
DECLARE @Src_Flt_Raw INT, @Src_Flt_Stg INT;

SELECT @Src_Air_Raw = table_id FROM ds_table WHERE table_name = 'airlines_source';
SELECT @Src_Air_Stg = table_id FROM ds_table WHERE table_name = 'airlines_stage';
SELECT @Src_Port_Raw = table_id FROM ds_table WHERE table_name = 'airports_source';
SELECT @Src_Port_Stg = table_id FROM ds_table WHERE table_name = 'airports_stage';
SELECT @Src_Flt_Raw = table_id FROM ds_table WHERE table_name = 'flights_source';
SELECT @Src_Flt_Stg = table_id FROM ds_table WHERE table_name = 'flights_stage';

-- Note: LSET set to '2020-01-01' here
IF NOT EXISTS (SELECT 1 FROM dataflow WHERE flow_name = 'Load Airlines Source to Stage')
    INSERT INTO dataflow (flow_name, source_table_id, destination_table_id, status, LSET, CET)
    VALUES ('Load Airlines Source to Stage', @Src_Air_Raw, @Src_Air_Stg, 'Active', '2020-01-01', '2020-01-01');

IF NOT EXISTS (SELECT 1 FROM dataflow WHERE flow_name = 'Load Airports Source to Stage')
    INSERT INTO dataflow (flow_name, source_table_id, destination_table_id, status, LSET, CET)
    VALUES ('Load Airports Source to Stage', @Src_Port_Raw, @Src_Port_Stg, 'Active', '2020-01-01', '2020-01-01');

IF NOT EXISTS (SELECT 1 FROM dataflow WHERE flow_name = 'Load Flights Source to Stage')
    INSERT INTO dataflow (flow_name, source_table_id, destination_table_id, status, LSET, CET)
    VALUES ('Load Flights Source to Stage', @Src_Flt_Raw, @Src_Flt_Stg, 'Active', '2020-01-01', '2020-01-01');


-- B. NDS -> DDS
DECLARE @NDS_ID INT, @DDS_ID INT;
SELECT @NDS_ID = store_id FROM ds_data_store WHERE store_name = 'NDS_AIRLINES';
SELECT @DDS_ID = store_id FROM ds_data_store WHERE store_name = 'DDS_AIRLINES';

DECLARE @Src_Airline INT, @Dest_Airline INT;
DECLARE @Src_Airport INT, @Dest_Airport INT;
DECLARE @Src_Flight INT,  @Dest_Flight INT;

SELECT @Src_Airline  = table_id FROM ds_table WHERE table_name = 'airline' AND store_id = @NDS_ID;
SELECT @Dest_Airline = table_id FROM ds_table WHERE table_name = 'Dim_Airline' AND store_id = @DDS_ID;
SELECT @Src_Airport  = table_id FROM ds_table WHERE table_name = 'airport' AND store_id = @NDS_ID;
SELECT @Dest_Airport = table_id FROM ds_table WHERE table_name = 'Dim_Airport' AND store_id = @DDS_ID;
SELECT @Src_Flight   = table_id FROM ds_table WHERE table_name = 'flight' AND store_id = @NDS_ID;
SELECT @Dest_Flight  = table_id FROM ds_table WHERE table_name = 'Fact_Flight' AND store_id = @DDS_ID;

-- Note: LSET set to '2020-01-01' here
IF NOT EXISTS (SELECT 1 FROM dataflow WHERE flow_name = 'Load_Dim_Airline')
    INSERT INTO dataflow (flow_name, source_table_id, destination_table_id, LSET, status)
    VALUES ('Load_Dim_Airline', @Src_Airline, @Dest_Airline, '2020-01-01', 'Ready');

IF NOT EXISTS (SELECT 1 FROM dataflow WHERE flow_name = 'Load_Dim_Airport')
    INSERT INTO dataflow (flow_name, source_table_id, destination_table_id, LSET, status)
    VALUES ('Load_Dim_Airport', @Src_Airport, @Dest_Airport, '2020-01-01', 'Ready');

IF NOT EXISTS (SELECT 1 FROM dataflow WHERE flow_name = 'Load_Fact_Flight')
    INSERT INTO dataflow (flow_name, source_table_id, destination_table_id, LSET, status)
    VALUES ('Load_Fact_Flight', @Src_Flight, @Dest_Flight, '2020-01-01', 'Ready');
GO

-- ====================================================
-- STEP 5: FORCE UPDATE (If rows already existed)
-- This ensures existing rows are also updated to 2020
-- ====================================================
UPDATE dataflow
SET LSET = '2020-01-01', CET = '2020-01-01'
WHERE LSET < '2020-01-01';

-- ====================================================
-- STEP 6: FINAL VERIFICATION
-- ====================================================

UPDATE dataflow
SET LSET = '2000-1-1'

SELECT 
    f.flow_name, 
    src.table_name AS [Source], 
    dest.table_name AS [Destination], 
    f.LSET AS [Last_Extraction_Time],
    f.CET AS [Current_Extraction_Time],
    f.status
FROM dataflow f
JOIN ds_table src ON f.source_table_id = src.table_id
JOIN ds_table dest ON f.destination_table_id = dest.table_id
ORDER BY f.flow_name;
