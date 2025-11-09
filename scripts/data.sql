USE metadata_airlines;
    GO

-- Data stores
INSERT INTO dbo.ds_data_store (store_name, description)
VALUES
('Source', 'Original raw data from CSV or external system'),
('Stage', 'Stage layer for initial cleansing and formatting');
GO
INSERT INTO dbo.ds_table_type (type_name, description)
VALUES
('Raw', 'Raw tables in Source'),
('Stage', 'Stage tables');
GO
-- 3.
-- Source tables
INSERT INTO dbo.ds_table (store_id, table_type_id, table_name, description)
VALUES
(1, 1, 'airlines_source', 'Raw airlines data from CSV file'),
(1, 1, 'airports_source', 'Raw airports data from CSV file'),
(1, 1, 'flights_source', 'Raw flights data from CSV file');

-- Stage tables
INSERT INTO dbo.ds_table (store_id, table_type_id, table_name, description)
VALUES
(2, 2, 'airlines_stage', 'Stage table for airlines data'),
(2, 2, 'airports_stage', 'Stage table for airports data'),
(2, 2, 'flights_stage', 'Stage table for flights data');

-- 4️. 
INSERT INTO ds_table (store_id, table_type_id, table_name)
VALUES
(2, 2, 'airlines_stage'),
(2, 2, 'airports_stage'),
(2, 2, 'flights_stage');

-- 5.   
INSERT INTO dataflow (flow_name, source_table_id, destination_table_id, status)
VALUES
('Load Airlines Source to Stage', 1, 4, 'Active'),
('Load Airports Source to Stage', 2, 5, 'Active'),
('Load Flights Source to Stage', 3, 6, 'Active');
        
UPDATE dataflow
SET LSET = '2000-01-01';

UPDATE dataflow
SET CET = '2000-01-01';

SELECT * FROM dataflow