USE dq_airlines;
GO

IF OBJECT_ID('dbo.dq_bad_rows', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dq_bad_rows (
        dq_id           INT IDENTITY(1,1) PRIMARY KEY,
        dq_table        NVARCHAR(100)  NULL,
        dq_rule         NVARCHAR(200)  NULL,
        dq_reason       NVARCHAR(500)  NULL,
        dq_detected_at  DATETIME2(0)   NOT NULL DEFAULT SYSDATETIME(),
        raw_data        NVARCHAR(MAX)  NULL
    );
END
GO

/* =========================
   1) AIRLINES – bad rows
   Rules:
   - Invalid_IATA = ISNULL(iata_trim) OR LEN(iata_trim) != 2
   - Invalid_AirlineName = ISNULL(name_trim) OR name_trim = ''
   ========================= */
use stage_airlines
-- (A) IATA sai độ dài (1 ký tự)
INSERT INTO dbo.airlines_stg (IATA_CODE, Airline)
VALUES ('A', 'DQ_TEST_AIRLINE_INVALID_IATA');

-- (B) AirlineName rỗng / NULL
INSERT INTO dbo.airlines_stg (IATA_CODE, Airline)
VALUES ('ZZ', NULL);   -- hoặc thay NULL bằng ''


/* =========================
   2) AIRPORTS – bad rows
   Rules:
   - Invalid_IATA = ISNULL(iata_trim) OR LEN(iata_trim) != 3
   - Invalid_LatLon = LATITUDE NOT BETWEEN -90 AND 90 OR LONGITUDE NOT BETWEEN -180 AND 180
   ========================= */

-- (A) IATA sai độ dài (2 ký tự)
INSERT INTO dbo.airports_stg (IATA_CODE, AIRPORT, CITY, STATE, COUNTRY, LATITUDE, LONGITUDE)
VALUES ('AA', 'DQ_TEST_AIRPORT_INVALID_IATA', 'DQ City', 'DQ', 'US', 10.0, 20.0);

-- (B) Lat/Lon vượt range (giữ IATA đúng 3 ký tự để chỉ fail rule LatLon)
INSERT INTO dbo.airports_stg (IATA_CODE, AIRPORT, CITY, STATE, COUNTRY, LATITUDE, LONGITUDE)
VALUES ('DQA', 'DQ_TEST_AIRPORT_INVALID_LATLON', 'DQ City', 'DQ', 'US', 95.0, 200.0);


/* =========================
   3) FLIGHTS – bad rows (insert vào 1 bảng stage, ở đây là flights_stg_1)
   Rules:
   - Invalid_Code
   - Invalid_TimeRange
   - Invalid_CancelLogic
   - Invalid_Range
   ========================= */

/* DQ test rows for flights_stg_1
*/
use stage_airlines
DECLARE @now DATETIME = GETDATE();

-- 1) Invalid_Code: AIRLINE sai độ dài (1 ký tự)
INSERT INTO dbo.flights_stg_1 (
  [DATE],[AIRLINE],[FLIGHT_NUMBER],[TAIL_NUMBER],[ORIGIN_AIRPORT],[DESTINATION_AIRPORT],
  [SCHEDULED_DEPARTURE],[DEPARTURE_TIME],[DEPARTURE_DELAY],[TAXI_OUT],[WHEELS_OFF],
  [SCHEDULED_TIME],[ELAPSED_TIME],[AIR_TIME],[DISTANCE],[WHEELS_ON],[TAXI_IN],
  [SCHEDULED_ARRIVAL],[ARRIVAL_TIME],[ARRIVAL_DELAY],[DIVERTED],[CANCELLED],[CANCELLATION_REASON],
  [AIR_SYSTEM_DELAY],[SECURITY_DELAY],[AIRLINE_DELAY],[LATE_AIRCRAFT_DELAY],[WEATHER_DELAY],
  [CREATED],[MODIFIED]
)
VALUES (
  '2015-01-01','A',99001,'DQTEST01','LGA','BWI',
  800, 810, 10, 15, 825,
  360, 355, 330, 2475, 1035, 10,
  1100, 1045, -15, 0, 0, NULL,
  0, 0, 0, 0, 0,
  @now, @now
);

-- 2) Invalid_TimeRange: chỉ làm sai SCHEDULED_DEPARTURE = 2360 (phút = 60)
INSERT INTO dbo.flights_stg_1 (
  [DATE],[AIRLINE],[FLIGHT_NUMBER],[TAIL_NUMBER],[ORIGIN_AIRPORT],[DESTINATION_AIRPORT],
  [SCHEDULED_DEPARTURE],[DEPARTURE_TIME],[DEPARTURE_DELAY],[TAXI_OUT],[WHEELS_OFF],
  [SCHEDULED_TIME],[ELAPSED_TIME],[AIR_TIME],[DISTANCE],[WHEELS_ON],[TAXI_IN],
  [SCHEDULED_ARRIVAL],[ARRIVAL_TIME],[ARRIVAL_DELAY],[DIVERTED],[CANCELLED],[CANCELLATION_REASON],
  [AIR_SYSTEM_DELAY],[SECURITY_DELAY],[AIRLINE_DELAY],[LATE_AIRCRAFT_DELAY],[WEATHER_DELAY],
  [CREATED],[MODIFIED]
)
VALUES (
  '2015-01-01','AA',99002,'DQTEST02','LGA','BWI',
  2360, 810, 0, 10, 820,
  360, 360, 340, 2475, 1030, 10,
  1100, 1105, 5, 0, 0, NULL,
  0, 0, 0, 0, 0,
  @now, @now
);

-- 3) Invalid_CancelLogic: CANCELLED = 1 nhưng CANCELLATION_REASON = NULL
INSERT INTO dbo.flights_stg_1 (
  [DATE],[AIRLINE],[FLIGHT_NUMBER],[TAIL_NUMBER],[ORIGIN_AIRPORT],[DESTINATION_AIRPORT],
  [SCHEDULED_DEPARTURE],[DEPARTURE_TIME],[DEPARTURE_DELAY],[TAXI_OUT],[WHEELS_OFF],
  [SCHEDULED_TIME],[ELAPSED_TIME],[AIR_TIME],[DISTANCE],[WHEELS_ON],[TAXI_IN],
  [SCHEDULED_ARRIVAL],[ARRIVAL_TIME],[ARRIVAL_DELAY],[DIVERTED],[CANCELLED],[CANCELLATION_REASON],
  [AIR_SYSTEM_DELAY],[SECURITY_DELAY],[AIRLINE_DELAY],[LATE_AIRCRAFT_DELAY],[WEATHER_DELAY],
  [CREATED],[MODIFIED]
)
VALUES (
  '2015-01-01','AA',99003,'DQTEST03','LGA','BWI',
  900, 905, 5, 12, 917,
  360, 365, 340, 2475, 1057, 8,
  1200, 1205, 5, 0, 1, NULL,
  0, 0, 0, 0, 0,
  @now, @now
);

-- 4) Invalid_Range: DISTANCE <= 0 (giữ DATE có giá trị để chỉ fail vì DISTANCE)
INSERT INTO dbo.flights_stg_1 (
  [DATE],[AIRLINE],[FLIGHT_NUMBER],[TAIL_NUMBER],[ORIGIN_AIRPORT],[DESTINATION_AIRPORT],
  [SCHEDULED_DEPARTURE],[DEPARTURE_TIME],[DEPARTURE_DELAY],[TAXI_OUT],[WHEELS_OFF],
  [SCHEDULED_TIME],[ELAPSED_TIME],[AIR_TIME],[DISTANCE],[WHEELS_ON],[TAXI_IN],
  [SCHEDULED_ARRIVAL],[ARRIVAL_TIME],[ARRIVAL_DELAY],[DIVERTED],[CANCELLED],[CANCELLATION_REASON],
  [AIR_SYSTEM_DELAY],[SECURITY_DELAY],[AIRLINE_DELAY],[LATE_AIRCRAFT_DELAY],[WEATHER_DELAY],
  [CREATED],[MODIFIED]
)
VALUES (
  '2015-01-01','AA',99004,'DQTEST04','LGA','BWI',
  700, 700, 0, 10, 710,
  360, 360, 340, 0, 1030, 10,
  1100, 1100, 0, 0, 0, NULL,
  0, 0, 0, 0, 0,
  @now, @now
);


use dq_airlines
select * from dq_bad_rows

--check dòng vừa thêm
USE stage_airlines
select * FROM dbo.airports_stg

--xóa dòng đã thêm
delete from dbo.flights_stg_1
where tail_number = 'DQTEST03'

/* Xoá bảng dbo.dq_bad_rows trong DB dq_airlines */
USE [dq_airlines];
GO

IF OBJECT_ID('dbo.dq_bad_rows', 'U') IS NOT NULL
    DROP TABLE dbo.dq_bad_rows;
GO