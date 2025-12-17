USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'dds_airlines')
BEGIN
    ALTER DATABASE dds_airlines SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE dds_airlines;
END
GO

CREATE DATABASE dds_airlines;
GO
USE dds_airlines;
GO

-- ============================================================
-- 1. Dim_Date
-- Dùng ?? phân tích theo Ngày, Tháng, N?m, Quý
-- ============================================================
CREATE TABLE [dbo].[Dim_Date] (
    DateKey INT PRIMARY KEY,              -- Smart SK: YYYYMMDD (VD: 20150101)
    FullDate DATE NOT NULL,
    Year INT,
    Quarter INT,
    Month INT,
    MonthName VARCHAR(20),
    DayOfWeek INT,
    DayName VARCHAR(20),
    IsWeekend BIT
);
GO

-- ============================================================
-- 2. Dim_Airport
-- SK: Airport_SK (Dùng JOIN)
-- BK: Airport_NDS_ID (Dùng Lookup v? NDS)
-- ============================================================
CREATE TABLE [dbo].[Dim_Airport] (
    Airport_SK INT IDENTITY(1,1) PRIMARY KEY,   
    
    -- Business Keys & References
    Airport_NDS_ID INT NOT NULL,               -- ID g?c t? b?ng 'airport' c?a NDS
    AirportCode VARCHAR(10) NOT NULL,          -- Mã IATA (Dùng VARCHAR ?? tránh l?i padding c?a CHAR)
    
    -- Attributes
    AirportName NVARCHAR(255),
    City VARCHAR(100),
    State VARCHAR(50),
    Country VARCHAR(100),
    Latitude DECIMAL(12,9),                   -- Matches Stage Precision
    Longitude DECIMAL(12,9), 
    
    -- SCD Metadata (Qu?n lý l?ch s? thay ??i)
    RowIsCurrent BIT DEFAULT 1,
    RowStartDate DATETIME2 DEFAULT GETDATE(),
    RowEndDate DATETIME2 NULL
);
GO

-- ============================================================
-- 3. Dim_Airline
-- SK: Airline_SK
-- BK: Airline_NDS_ID
-- ============================================================
CREATE TABLE [dbo].[Dim_Airline] (
    Airline_SK INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Business Keys & References
    Airline_NDS_ID INT NOT NULL,               -- Khóa kết nối với NDS
    AirlineCode VARCHAR(10) NOT NULL,          -- Mã IATA
    
    -- Attributes (Sẽ bị ghi đè nếu thay đổi)
    AirlineName NVARCHAR(255),
    
    -- SCD Type 1 Metadata (Chỉ cần biết tạo khi nào và sửa khi nào)
    CreatedDate DATETIME2 DEFAULT GETDATE(),   -- Ngày dòng này được Insert lần đầu
    UpdatedDate DATETIME2 DEFAULT GETDATE()    -- Ngày dòng này được Update lần cuối
);

-- ============================================================
-- 4. Dim_CancellationReason
-- SK: Reason_SK
-- ============================================================
CREATE TABLE [dbo].[Dim_CancellationReason] (
    Reason_SK INT IDENTITY(1,1) PRIMARY KEY,
    ReasonCode CHAR(1),                        -- A, B, C, D
    ReasonDescription NVARCHAR(100)            -- Weather, Carrier, Security...
);
GO

-- ============================================================
-- 5. Fact_Flight
-- Ch?a Metrics và Keys. Các c?t th?i gian dùng DATETIME nh? NDS.
-- ============================================================
CREATE TABLE [dbo].[Fact_Flight] (
    FactID BIGINT IDENTITY(1,1) PRIMARY KEY,

    -- ===========================
    -- FOREIGN KEYS (Tr? vào SK)
    -- ===========================
    DateKey INT NOT NULL,                      -- FK -> Dim_Date
    Airline_SK INT NOT NULL,                   -- FK -> Dim_Airline
    OriginAirport_SK INT NOT NULL,             -- FK -> Dim_Airport
    DestAirport_SK INT NOT NULL,               -- FK -> Dim_Airport
    CancellationReason_SK INT NOT NULL,        -- FK -> Dim_CancellationReason

    -- ===========================
    -- DEGENERATE DIMENSIONS (Thông tin ??nh danh)
    -- ===========================
    FlightNumber INT,
    TailNumber VARCHAR(20),

    -- ===========================
    -- TIMESTAMPS (Kh?p v?i NDS m?i)
    -- Dùng ?? tính toán chi ti?t n?u c?n thi?t
    -- ===========================
    ScheduledDeparture DATETIME,
    ScheduledArrival DATETIME,
    ActualDeparture DATETIME,                  -- T??ng ?ng departure_time
    ActualArrival DATETIME,                    -- T??ng ?ng arrival_time
    WheelsOff DATETIME,
    WheelsOn DATETIME,

    -- ===========================
    -- MEASURES (S? li?u ??nh l??ng)
    -- ===========================
    DepDelayMinutes FLOAT DEFAULT 0,
    ArrDelayMinutes FLOAT DEFAULT 0,
    AirTime FLOAT,
    Distance FLOAT,
    TaxiOut FLOAT,
    TaxiIn FLOAT,
    
    -- Delay Breakdown Measures
    AirSystemDelay FLOAT,
    SecurityDelay FLOAT,
    AirlineDelay FLOAT,
    LateAircraftDelay FLOAT,
    WeatherDelay FLOAT,

    IsCancelled BIT DEFAULT 0,
    IsDiverted BIT DEFAULT 0,

    -- Audit
    CreatedDate DATETIME2 DEFAULT GETDATE()
);


ALTER TABLE Fact_Flight ADD CONSTRAINT FK_Fact_Date FOREIGN KEY (DateKey) REFERENCES Dim_Date(DateKey);
ALTER TABLE Fact_Flight ADD CONSTRAINT FK_Fact_Airline FOREIGN KEY (Airline_SK) REFERENCES Dim_Airline(Airline_SK);
ALTER TABLE Fact_Flight ADD CONSTRAINT FK_Fact_Origin FOREIGN KEY (OriginAirport_SK) REFERENCES Dim_Airport(Airport_SK);
ALTER TABLE Fact_Flight ADD CONSTRAINT FK_Fact_Dest FOREIGN KEY (DestAirport_SK) REFERENCES Dim_Airport(Airport_SK);
ALTER TABLE Fact_Flight ADD CONSTRAINT FK_Fact_Reason FOREIGN KEY (CancellationReason_SK) REFERENCES Dim_CancellationReason(Reason_SK);
GO


-- A. Unknown Date (19000101)
INSERT INTO Dim_Date (DateKey, FullDate, Year, Quarter, Month, MonthName, DayOfWeek, DayName, IsWeekend)
VALUES (19000101, '1900-01-01', 1900, 1, 1, 'January', 1, 'Monday', 0);

-- B. Unknown Airline
SET IDENTITY_INSERT [dbo].[Dim_Airline] ON;
INSERT INTO [dbo].[Dim_Airline] (Airline_SK, Airline_NDS_ID, AirlineCode, AirlineName, CreatedDate, UpdatedDate)
VALUES (-1, -1, 'UNK', 'Unknown Airline', '1900-01-01', '1900-01-01');
SET IDENTITY_INSERT [dbo].[Dim_Airline] OFF;
GO

-- C. Unknown Airport
SET IDENTITY_INSERT Dim_Airport ON;
INSERT INTO Dim_Airport (Airport_SK, Airport_NDS_ID, AirportCode, AirportName, City, State, Country, RowIsCurrent, RowStartDate)
VALUES (-1, -1, 'UNK', 'Unknown Airport', 'N/A', 'N/A', 'N/A', 1, '1900-01-01');
SET IDENTITY_INSERT Dim_Airport OFF;

-- D. Unknown Cancellation Reason (Dùng cho chuy?n bay KHÔNG b? h?y)
SET IDENTITY_INSERT Dim_CancellationReason ON;
INSERT INTO Dim_CancellationReason (Reason_SK, ReasonCode, ReasonDescription)
VALUES (-1, 'N', 'Not Cancelled / Unknown');
SET IDENTITY_INSERT Dim_CancellationReason OFF;

SELECT * FROM Dim_Date
SELECT * FROM Dim_CancellationReason
SELECT * FROM Dim_Airline
SELECT * FROM Fact_Flight