# Airline Data Warehouse & Analytics Platform

## Overview

This project focuses on the design and implementation of a Data Warehouse (DW) system for the airline industry. The objective is to transform raw flight-related data into a centralized analytical repository that supports reporting, performance analysis, and decision-making.

The Data Warehouse integrates multiple source files related to airlines, airports, and flight operations through a structured ETL process. The final system enables historical analysis of flight volume, on-time performance, delays, cancellations, and operational efficiency across airlines and airports.

The project follows a full data lifecycle approach, including data modeling, ETL development, OLAP querying, dashboard visualization, and data mining.

---

## Dataset

The project uses airline operational datasets provided via the course Moodle system.

### Dataset Origin and Scope

The datasets are derived from the public airline delay dataset (for reference only):

https://www.kaggle.com/datasets/usdot/flight-delays

Important notes:
- The original Kaggle dataset is **NOT used directly**.
- The datasets provided on Moodle are **filtered, simplified, and reduced in size**.
- Only the provided files are allowed and used in this project.
- The simplified datasets are designed to support learning objectives and project constraints rather than full-scale industry deployment.

### Source Data Files

The Data Warehouse is built from the following five CSV files:

- `airlines.csv`  
  Airline master data (airline codes and names)

- `filtered_airports.csv`  
  Airport reference data, filtered to relevant airports only

- `filtered_flights_1.csv`  
  Flight operations data (part 1)

- `filtered_flights_2.csv`  
  Flight operations data (part 2)

- `filtered_flights_3.csv`  
  Flight operations data (part 3)

The three flight files together form a **partitioned subset of flight operational records**, used to simulate larger datasets while maintaining manageable data volume.

---

## Architecture Overview

The system is designed using a layered architecture to ensure scalability, maintainability, and analytical efficiency:

- **Staging Layer**  
  Raw data ingestion, validation, and basic cleansing

- **Data Warehouse Layer**  
  Dimensional data model optimized for analytical queries

- **Analytics Layer**  
  OLAP queries, aggregations, and KPI calculations

- **Visualization Layer**  
  Dashboards and reports for management and operational analysis

- **Advanced Analytics Layer**  
  Data mining and predictive modeling

---

## Data Warehouse Design

The data flows through four distinct layers to ensure data quality, normalization, and analytical performance:

1. Raw Data Ingestion: Bulk loading CSV files into the Source Database (SQL Server).
2. Staging Layer (Stage): Extracts data from the Source DB. Acts as a temporary buffer with no transformations.
3. Normalized Data Store (NDS): A 3NF (Third Normal Form) database that integrates data, enforces relationships, and cleanses data.
4. Dimensional Data Store (DDS): A Star Schema design optimized for OLAP queries and Power BI reporting.

## ETL Process

The ETL pipeline is orchestrated via a Master Package (master.dtsx) executing three sub-packages sequentially.

**Pre-requisite: Data Ingestion**
- Process: Raw CSV files (airlines.csv, airports.csv, flights.csv) are loaded into the Source Database using T-SQL BULK INSERT or Import Wizards. This ensures high-speed ingestion before complex transformations begin.

**Phase 1: Source DB to Stage (SourcetoStage.dtsx)**
- Objective: Extract data from the Source Database into Staging.
- Workflow:
    1. Truncate: Clears all staging tables to prevent data duplication.
    2. Parallel Extraction: Loads Reference Data (Airlines, Airports).
    3. Load Flights Data using Incremental load technique.

**Phase 2: Stage to NDS (StagetoNDS.dtsx)**
- Objective: Cleanse and Normalize data into 3NF.
- Transformations:
    - Data Type conversion (String to DateTime/Decimal).
    - Lookup standardizations.
    - Loading normalized tables: airline, airport, flight.
**Phase 3: NDS to DDS (NDStoDDS.dtsx)**
- Objective: Load the Star Schema.

- Dimension Load:
    - Populate Dim_Date
    - Loads Dim_Airline, Dim_CancellationReason and Dim_Airport.
    - Fact Load (Fact_Flight)
## Analytical Queries (OLAP)

The Data Warehouse supports the following core analytical queries:

- Total number of flights by month, quarter, and year
- Top 5 busiest airports based on total departures and arrivals
- On-Time Performance (OTP ± 5 minutes) by airport
- Flight cancellation rate by cancellation reason
- Average delay time by departure airport and arrival airport

All analytical queries are implemented using SQL and OLAP techniques.

Follow the steps below to run everything end-to-end.


### 1) Requirements

#### Software
- Windows
- **SQL Server Database Engine**
- **SQL Server Analysis Services (SSAS) — Multidimensional mode**
- **Visual Studio + SSDT / Analysis Services Projects extension**
- **SQL Server Management Studio (SSMS)**


### 2) Database

After you run the ETL project here **https://github.com/toilahd/N012-AirlineDW.git** you will have data in dds_airlines database.


### 3) Create/Update SQL Views

Run the provided view script on the restored database:

1. In **SSMS** → New Query
2. Execute the provided `create_view` script


### 4) Open the SSAS project

1. Open Visual Studio
2. Open the `.sln` file from this repository


### 5) Configure the SSAS Data Source (important)

1. In **Solution Explorer** → **Data Sources**
2. Open `dds_airlines.ds`
3. Edit the connection:
   - SQL Server instance name (your machine)
   - Authentication (Windows Auth recommended)
   - Database: `dds_airlines`
4. Click **Test Connection** → **OK** → Save


### 6) Deploy to SSAS and Process the cube (build the OLAP database)

1. Right-click the project → **Properties**
2. Go to **Deployment**
3. Set:
   - **Server**: your SSAS instance name
   - **Database**: `OLAP` (or any name you want)
4. Click **OK**
5. Right-click project → **Build** 
6. Right-click project → **Deploy**
7. Right-click project → **Process**
8. Choose **Process Full** → Run


### 7) Run MDX queries (validation)

1. In **SSMS** → connect to **Analysis Services**
2. New Query → select cube database
3. Open `scripts/OLAP.mdx` from this repo (or paste queries)
4. Execute queries

---

## Dashboards & Visualization

Dashboards are implemented using Power BI

### Management Dashboard

Key performance indicators include:
- Total number of flights
- Overall On-Time Performance (OTP)
- Flight cancellation rate
- Percentage of flights delayed more than 15 minutes
- Top 5 airlines by OTP
- Top 5 airports with the highest delay rate
- Flight volume trends by month and quarter

### Root Cause & Operational Analysis

- Delay distribution by reason
- Average delay duration by delay cause
- Delay trends by month and season
- Delay patterns by time of day
- Airports contributing most to delays and cancellations

Dashboards include appropriate filters, slicers, and drill-down capabilities to support interactive analysis.

---

## Data Mining & Prediction

Data mining components for predictive analytics and pattern discovery will be implemented in the mining/ directory.

---

## Repository Structure

```
N012-AirlineDW/
│
├── data/                           # Raw data files
│   ├── airlines.csv                # Airline master data
│   ├── filtered_airpoirt.csv       # Airport reference data
│   ├── filtered_flights_1.csv      # Flight operations (part 1)
│   ├── filtered_flights_2.csv      # Flight operations (part 2)
│   └── filtered_flights_3.csv      # Flight operations (part 3)
│
├── scripts/                        # Database SQL scripts
│   ├── source.sql                  # Source database schema
│   ├── stage.sql                   # Staging layer schema
│   ├── nds.sql                     # Normalized Data Store schema
│   ├── dds.sql                     # Dimensional Data Store schema
│   ├── metadata.sql                # Metadata management
│   └── data.sql                    # Data loading scripts
│
├── etl/                            # ETL packages (SSIS)
│   ├── master.dtsx                 # Master orchestration package
│   ├── SourcetoStage.dtsx          # Source to Stage ETL
│   ├── StagetoNDS.dtsx             # Stage to NDS ETL
│   ├── NDStoDDS.dtsx               # NDS to DDS ETL
│   ├── etl.sln                     # Visual Studio solution
│   ├── etl.dtproj                  # SSIS project file
│   └── Project.params              # Project parameters
│
├── mining/                         # Data mining & analytics
│
├── visualization/                  # Power BI dashboards & reports
│
└── README.md                       # Project documentation
```

---

## Technology Stack

- **ETL Tool**: SQL Server Integration Services (SSIS) / Visual Studio 2022
- **Database Engine**: SQL Server 2022
- **Languages**: T-SQL (Stored Procedures, Scripts)
- **Visualization**: Power BI Desktop
- **Data Mining**: Python


