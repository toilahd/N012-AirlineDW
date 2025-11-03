USE master;
ALTER DATABASE metadata_airlines SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE IF EXISTS metadata_airlines;
GO
CREATE DATABASE metadata_airlines
GO
USE metadata_airlines



-- DATA STRUCTURE METADATA TABLES

CREATE TABLE [dbo].[ds_data_store](
    store_id INT IDENTITY(1,1) PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

GO 

CREATE TABLE [dbo].[ds.table_type](
    type_id INT IDENTITY(1,1) PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    description VARCHAR(255) NULL
)

CREATE TABLE [dbo].[ds_table](
    table_id INT IDENTITY(1,1) PRIMARY KEY,
    store_id INT NOT NULL,
    table_type_id INT NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    schema_definition TEXT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (store_id) REFERENCES ds_data_store(store_id),
    FOREIGN KEY (table_type_id) REFERENCES ds.table_type(type_id)
);

CREATE TABLE [dbo].[ds_column](
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
DROP TABLE IF EXISTS dataflow;
GO

CREATE TABLE [dbo].[dataflow](
    flow_id INT IDENTITY(1,1) PRIMARY KEY,
    flow_name VARCHAR(100) NOT NULL,
    source_table table_id INT NOT NULL,
    destination_table_id INT NOT NULL,
    last_extraction_date DATETIME NULL,
    status VARCHAR(50) NULL,
    FOREIGN KEY (source_table_id) REFERENCES ds_table(table_id),
    FOREIGN KEY (destination_table_id) REFERENCES ds_table(table_id)

);

GO