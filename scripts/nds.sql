-- =============================
-- NDS (Normalized Data Store) in 3NF
-- Optimized for Data Integrity and Basic Reporting Performance
-- =============================

USE master;
GO

-- 1. Drop and create NDS database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'nds_airlines')
BEGIN
    ALTER DATABASE nds_airlines SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE nds_airlines;
END
GO

CREATE DATABASE nds_airlines;
GO

USE nds_airlines;
GO

-- =============================
-- 2. SOURCE TABLE (Metadata)
-- =============================
CREATE TABLE [dbo].[source] (
    source_id INT IDENTITY(1,1) PRIMARY KEY,
    source_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500),
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE()
);

-- Insert default sources matching your Stage tables
INSERT INTO [dbo].[source] (source_name, description)
VALUES 
    ('STAGE_AIRLINES', 'Staging table for airline data'),
    ('STAGE_AIRPORTS', 'Staging table for airport data'),
    ('STAGE_FLIGHTS_1', 'Staging table for flight data batch 1'),
    ('STAGE_FLIGHTS_2', 'Staging table for flight data batch 2'),
    ('STAGE_FLIGHTS_3', 'Staging table for flight data batch 3');
GO

-- =============================
-- 3. AIRLINE TABLE (3NF)
-- =============================
CREATE TABLE [dbo].[airline] (
    airline_id INT IDENTITY(1,1) PRIMARY KEY,
    airline_code CHAR(2) NOT NULL UNIQUE, -- Maps to IATA_CODE
    airline_name NVARCHAR(255) NOT NULL,       -- Maps to Airline
    source_id INT NOT NULL,
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_airline_source FOREIGN KEY (source_id) REFERENCES [dbo].[source](source_id)
);
GO

-- =============================
-- 4. AIRPORT TABLE (3NF)
-- =============================
CREATE TABLE [dbo].[airport] (
    airport_id INT IDENTITY(1,1) PRIMARY KEY,
    airport_code CHAR(10) NOT NULL UNIQUE, -- Maps to IATA_CODE
    airport_name NVARCHAR(255) NOT NULL,       -- Maps to AIRPORT
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(100),
    latitude DECIMAL(12,9),                   -- Matches Stage Precision
    longitude DECIMAL(12,9),                  -- Matches Stage Precision
    source_id INT NOT NULL,
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_airport_source FOREIGN KEY (source_id) REFERENCES [dbo].[source](source_id)
);
GO

-- =============================
-- 5. FLIGHT TABLE (3NF)
-- =============================
CREATE TABLE [dbo].[flight] (
    flight_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Foreign Keys (Surrogate Keys from Dimension Tables)
    airline_id INT NOT NULL,
    origin_airport_id INT NOT NULL,
    destination_airport_id INT NOT NULL,
    
    -- Flight Identifiers
    flight_number INT NOT NULL,
    tail_number VARCHAR(20),
    flight_date DATE NULL,
    
    -- Schedule Information
    scheduled_departure DATETIME, -- Matches Stage CHAR(10)
    scheduled_arrival DATETIME,
    scheduled_time FLOAT,
    
    -- Actual Times
    departure_time DATETIME,
    arrival_time DATETIME,
    wheels_off DATETIME,
    wheels_on DATETIME,
    
    -- Time Measures
    elapsed_time FLOAT,
    air_time FLOAT,
    taxi_out FLOAT,
    taxi_in FLOAT,
    
    -- Delay Measures
    departure_delay FLOAT,
    arrival_delay FLOAT,
    
    -- Delay Breakdown
    air_system_delay FLOAT,
    security_delay FLOAT,
    airline_delay FLOAT,
    late_aircraft_delay FLOAT,
    weather_delay FLOAT,
    
    -- Distance
    distance FLOAT,
    
    -- Status Flags
    diverted INT,
    cancelled INT,
    cancellation_reason VARCHAR(1),
    
    -- Metadata
    source_id INT NOT NULL,
    created_date DATETIME2 DEFAULT GETDATE(),
    updated_date DATETIME2 DEFAULT GETDATE(),
    
    -- Foreign Key Constraints
    CONSTRAINT fk_flight_airline FOREIGN KEY (airline_id) REFERENCES [dbo].[airline](airline_id),
    CONSTRAINT fk_flight_origin FOREIGN KEY (origin_airport_id) REFERENCES [dbo].[airport](airport_id),
    CONSTRAINT fk_flight_destination FOREIGN KEY (destination_airport_id) REFERENCES [dbo].[airport](airport_id),
    CONSTRAINT fk_flight_source FOREIGN KEY (source_id) REFERENCES [dbo].[source](source_id)
);
GO



-- =============================
-- VALIDATION QUERIES
-- =============================
SELECT t.name AS TableName, p.rows AS [RowCount]
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE t.is_ms_shipped = 0 AND p.index_id IN (0,1)
ORDER BY t.name;
GO

SELECT * FROM airport;
SELECT * FROM [dbo].source;
SELECT * FROM airline;
SELECT * FROM flight;