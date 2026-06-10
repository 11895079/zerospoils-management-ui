-- ZeroSpoils Analytics Database Initialization
-- This script initializes the DuckDB database with all schema and dimension data

-- Load all schema files
.read duckdb/schema/dimensions.sql
.read duckdb/schema/facts.sql
.read duckdb/schema/marts.sql

-- Populate date dimension for the last 3 years
-- (Helper: this will be done via Node.js during ETL setup)

-- Create extension for JSON support (for ETL processing)
INSTALL json;
LOAD json;

-- Create helper functions for ETL
-- Hash function for stable fact ID generation (deterministic deduplication)
CREATE MACRO stable_fact_id(event_data) AS
  md5(event_data::VARCHAR);

-- Function to extract year/month/day from timestamp for date dimension
CREATE MACRO extract_date_parts(ts) AS
  {
    year: year(ts),
    month: month(ts),
    day: day(ts),
    day_of_week: weekday(ts),
    week_of_year: weekofyear(ts)
  };

-- Sample data seed (for testing before real telemetry integration)
-- This will be populated by ETL in production
INSERT INTO dim_app_version (version, major, minor, patch, release_channel)
VALUES
  ('1.0.0', 1, 0, 0, 'stable'),
  ('1.1.0', 1, 1, 0, 'stable'),
  ('1.2.0', 1, 2, 0, 'stable'),
  ('2.0.0', 2, 0, 0, 'stable'),
  ('2.1.0-beta', 2, 1, 0, 'beta'),
  ('2.1.0-alpha', 2, 1, 0, 'alpha')
ON CONFLICT (version) DO NOTHING;

-- Verify all tables exist
SELECT
  table_name,
  COUNT(*) as row_count
FROM information_schema.tables
WHERE table_schema = 'main'
GROUP BY table_name
ORDER BY table_name;
