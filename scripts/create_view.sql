USE dds_airlines;
GO

CREATE OR ALTER VIEW dbo.vDim_Airport_Current AS
SELECT
    Airport_SK,
    AirportCode,
    AirportName,
    City, State, Country,
    Latitude, Longitude
FROM dbo.Dim_Airport
WHERE RowIsCurrent = 1;
GO

CREATE OR ALTER VIEW dbo.vFact_Flight AS
SELECT
    FactID,
    DateKey,
    Airline_SK,
    OriginAirport_SK,
    DestAirport_SK,
    CancellationReason_SK,

    FlightNumber,
    TailNumber,

    ScheduledDeparture,
    ScheduledArrival,
    ActualDeparture,
    ActualArrival,
    WheelsOff,
    WheelsOn,

    DepDelayMinutes,
    ArrDelayMinutes,
    AirTime,
    Distance,
    TaxiOut,
    TaxiIn,

    AirSystemDelay,
    SecurityDelay,
    AirlineDelay,
    LateAircraftDelay,
    WeatherDelay,

    IsCancelled,
    IsDiverted,

	CASE WHEN IsCancelled = 1 THEN 1 ELSE 0 END AS IsCancelled_Flag,

    CASE
      WHEN IsCancelled = 0 AND IsDiverted = 0 AND ArrDelayMinutes IS NOT NULL THEN 1 ELSE 0
    END AS Eligible_Flag,

    CASE
      WHEN IsCancelled = 0 AND IsDiverted = 0
           AND ArrDelayMinutes IS NOT NULL
           AND ABS(ArrDelayMinutes) <= 5 THEN 1 ELSE 0
    END AS OnTime5_Flag,

    CASE
      WHEN IsCancelled = 0 AND IsDiverted = 0
           AND ArrDelayMinutes IS NOT NULL
           AND ArrDelayMinutes > 15 THEN 1 ELSE 0
    END AS Delay15_Flag
FROM dbo.Fact_Flight;
GO
