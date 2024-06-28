#!/bin/bash

echo "Intialize hive schema"
set -e

# Check if the Metastore database already exists
if [ $(psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'") = '1' ]
then
    echo "Database ${POSTGRES_DB} already exists"
else
    # Create the Metastore database
    createdb -U postgres ${POSTGRES_DB}

    # Download the Hive Metastore schema
    curl -O https://raw.githubusercontent.com/apache/hive/master/standalone-metastore/src/main/scripts/postgres/hive-schema-3.1.0.postgres.sql

    # Apply the Hive Metastore schema
    psql -U postgres -d ${POSTGRES_DB} -f hive-schema-3.1.0.postgres.sql

    # Clean up
    rm hive-schema-3.1.0.postgres.sql
fi
