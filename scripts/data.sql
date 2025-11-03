-- 1️⃣ Register data stores
INSERT INTO ds_data_store (store_name, description)
VALUES 
('CSV_Source', 'Raw CSV files stored in /data/airlines/'),
('Stage_Airlines', 'Staging database for airline ETL');

-- 2
INSERT INTO ds_table_type (type_name, description)
VALUES 
('Source', 'Raw source data, e.g. CSV'),
('Stage', 'Staging layer tables'),
('DW', 'Data warehouse target tables');

-- 3️⃣ Register source CSV “tables”
INSERT INTO ds_table (store_id, table_type_id, table_name, schema_definition)
VALUES
(1, 1, 'airlines.csv', 'IATA_CODE CHAR(3), AIRLINE VARCHAR(100)'),
(1, 1, 'airports.csv', 'IATA_CODE CHAR(3), AIRPORT VARCHAR(100), CITY VARCHAR(100), STATE CHAR(2), COUNTRY VARCHAR(100), LATITUDE FLOAT, LONGITUDE FLOAT'),
(1, 1, 'flights.csv', 'FLIGHT_DATE DATE, AIRLINE CHAR(3), ...');

-- 4️⃣ Register corresponding stage tables
INSERT INTO ds_table (store_id, table_type_id, table_name)
VALUES
(2, 2, 'airlines_stage'),
(2, 2, 'airports_stage'),
(2, 2, 'flights_stage');

-- 5️⃣ Define dataflow (CSV → Stage)
INSERT INTO dataflow (flow_name, source_table_id, destination_table_id, status)
VALUES
('Load Airlines CSV to Stage', 1, 4, 'Active'),
('Load Airports CSV to Stage', 2, 5, 'Active'),
('Load Flights CSV to Stage', 3, 6, 'Active');
    