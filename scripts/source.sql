-- =============================
-- 1. DROP DATABASE IF EXISTS
-- =============================
USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'source_db')
BEGIN
    ALTER DATABASE source_db SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE source_db;
END
GO


-- =============================
-- 2. CREATE DATABASE
-- =============================
CREATE DATABASE source_db;
GO

USE source_db;
GO

DROP TABLE IF EXISTS airlines;
DROP TABLE IF EXISTS airport;
DROP TABLE IF EXISTS flights_1;
DROP TABLE IF EXISTS flights_2;
DROP TABLE IF EXISTS flights_3;

-- =============================
-- 3. CREATE TABLE: airlines
-- =============================
CREATE TABLE airlines (
    IATA_CODE VARCHAR(10) PRIMARY KEY,
    Airline VARCHAR(255)
);

-- =============================
-- 4. CREATE TABLE: airport
-- =============================
CREATE TABLE airport (
    IATA_CODE VARCHAR(10) PRIMARY KEY,
    AIRPORT VARCHAR(255),
    CITY VARCHAR(100),
    STATE VARCHAR(50),
    COUNTRY VARCHAR(100),
    LATITUDE DECIMAL(12,9),
    LONGITUDE DECIMAL(12,9)
);


-- =============================
-- 5. CREATE TABLE TEMPLATE for flights
-- =============================
CREATE TABLE flights_1 (
    DATE DATE,
    AIRLINE VARCHAR(10),
    FLIGHT_NUMBER INT,
    TAIL_NUMBER VARCHAR(20),
    ORIGIN_AIRPORT CHAR(10),
    DESTINATION_AIRPORT CHAR(10),
    SCHEDULED_DEPARTURE CHAR(10),
    DEPARTURE_TIME CHAR(10),
    DEPARTURE_DELAY FLOAT,
    TAXI_OUT FLOAT,
    WHEELS_OFF CHAR(10),
    SCHEDULED_TIME FLOAT,
    ELAPSED_TIME FLOAT,
    AIR_TIME FLOAT,
    DISTANCE FLOAT,
    WHEELS_ON CHAR(10),
    TAXI_IN FLOAT,
    SCHEDULED_ARRIVAL CHAR(10),
    ARRIVAL_TIME CHAR(10),
    ARRIVAL_DELAY FLOAT,
    DIVERTED INT,
    CANCELLED INT,
    CANCELLATION_REASON VARCHAR(1),
    AIR_SYSTEM_DELAY FLOAT,
    SECURITY_DELAY FLOAT,
    AIRLINE_DELAY FLOAT,
    LATE_AIRCRAFT_DELAY FLOAT,
    WEATHER_DELAY FLOAT,
    CREATED DATETIME2,
    MODIFIED DATETIME2
);

GO

-- ============================================================
-- 6. Create tables: flights_2 and flights_3 (same schema)
-- ============================================================

SELECT * INTO flights_2 FROM flights_1 WHERE 1=0;
SELECT * INTO flights_3 FROM flights_1 WHERE 1=0;
GO

-- =============================
-- 7. BULK INSERT data from CSV files
-- =============================

-- 1. Import airlines.csv
BULK INSERT airlines
FROM 'D:\Workspace\N012-AirlineDW\data\airlines.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,                 -- Skip header row
    FIELDTERMINATOR = ',',        -- CSV delimiter
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    KEEPNULLS,
    CODEPAGE = '65001'            -- UTF-8 encoding
);

-- 2. Import airport.csv
BULK INSERT airport
FROM 'D:\Workspace\N012-AirlineDW\data\filtered_airpoirt.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    KEEPNULLS,
    CODEPAGE = '65001'
);

-- 3. Import flights_1.csv
BULK INSERT flights_1
FROM 'D:\Workspace\N012-AirlineDW\data\filtered_flights_1.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    KEEPNULLS,
    CODEPAGE = '65001'
);

-- Same for flights_2 and flights_3
BULK INSERT flights_2
FROM 'D:\Workspace\N012-AirlineDW\data\filtered_flights_2.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);

BULK INSERT flights_3
FROM 'D:\Workspace\N012-AirlineDW\data\filtered_flights_3.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    KEEPNULLS,
    CODEPAGE = '65001'
);


