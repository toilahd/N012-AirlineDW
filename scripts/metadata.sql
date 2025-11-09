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



