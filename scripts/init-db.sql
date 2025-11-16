-- Initialize Nillion Micropayment Protocol Database
-- This script runs on first database creation

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- Enable UUID generation
-- gen_random_uuid() is built-in to PostgreSQL 13+, but adding for compatibility
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create initial schema version tracking table
CREATE TABLE IF NOT EXISTS schema_migrations (
  version VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Insert initial migration marker
INSERT INTO schema_migrations (version) VALUES ('init-000-baseline')
ON CONFLICT (version) DO NOTHING;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Nillion Micropayment Protocol database initialized successfully';
  RAISE NOTICE 'TimescaleDB version: %', (SELECT extversion FROM pg_extension WHERE extname = 'timescaledb');
  RAISE NOTICE 'PostgreSQL version: %', version();
END $$;
