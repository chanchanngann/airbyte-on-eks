CREATE USER cdc_user PASSWORD 'Password123';

GRANT USAGE ON SCHEMA public TO cdc_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cdc_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO cdc_user;

GRANT USAGE ON SCHEMA cdc_source TO cdc_user;
GRANT SELECT ON ALL TABLES IN SCHEMA cdc_source TO cdc_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA cdc_source GRANT SELECT ON TABLES TO cdc_user;

-- Give the user replication privileges. This allows Airbyte to create logical replication slots
GRANT rds_replication TO cdc_user;