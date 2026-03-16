-- InteraEdu Database Initialization Script
-- Creates separate schemas for each microservice

CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS profile;
CREATE SCHEMA IF NOT EXISTS feed;
CREATE SCHEMA IF NOT EXISTS messaging;

-- Grant usage to the application user
GRANT USAGE ON SCHEMA auth TO interaedu;
GRANT USAGE ON SCHEMA profile TO interaedu;
GRANT USAGE ON SCHEMA feed TO interaedu;
GRANT USAGE ON SCHEMA messaging TO interaedu;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO interaedu;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA profile TO interaedu;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA feed TO interaedu;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA messaging TO interaedu;

-- Default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON TABLES TO interaedu;
ALTER DEFAULT PRIVILEGES IN SCHEMA profile GRANT ALL ON TABLES TO interaedu;
ALTER DEFAULT PRIVILEGES IN SCHEMA feed GRANT ALL ON TABLES TO interaedu;
ALTER DEFAULT PRIVILEGES IN SCHEMA messaging GRANT ALL ON TABLES TO interaedu;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
