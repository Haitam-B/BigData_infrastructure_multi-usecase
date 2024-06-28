#!/bin/bash

# Start PostgreSQL service (only for embedded Postgres)
# service postgresql start

# Initialize Hive schema
if [ ! -f /opt/hive/metastore_db_initialized ]; then
    schematool -dbType postgres -initSchema
    touch /opt/hive/metastore_db_initialized
fi

# Start Hive services
hive --service metastore &
hive --service hiveserver2 &

# Keep the container running
tail -f /dev/null
