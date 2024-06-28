#!/bin/bash
set -e

# Ensure PostgreSQL data directory exists and has the right permissions
mkdir -p "$PGDATA"
chown -R postgres:postgres "$PGDATA"

# Ensure /run/postgresql directory exists and has the right permissions
mkdir -p /run/postgresql
chown -R postgres:postgres /run/postgresql

# Initialize the database if not already initialized
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "Initializing database"
  gosu postgres initdb
fi


# Start PostgreSQL server in the background
gosu postgres pg_ctl -D "$PGDATA" -o "-c listen_addresses='*'" -l "$PGDATA/logfile" -w start || {
    echo "PostgreSQL server failed to start. Here is the log output:"
    cat "$PGDATA/logfile"
    exit 1
}

# Ensure hive user and metastore database are created
gosu postgres psql <<- EOSQL
    DO
    \$do\$
    BEGIN
        IF NOT EXISTS (
            SELECT
            FROM   pg_catalog.pg_roles
            WHERE  rolname = '${POSTGRES_USER}') THEN

            CREATE ROLE ${POSTGRES_USER} LOGIN PASSWORD '${POSTGRES_PASSWORD}';
        END IF;
    END
    \$do\$;

    CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};
EOSQL

# Execute the schema initialization script
if [ -d /docker-entrypoint-initdb.d ]; then
  for f in /docker-entrypoint-initdb.d/*; do
    case "$f" in
      *.sh)     echo "$0: running $f"; . "$f" ;;
      *.sql)    echo "$0: running $f"; gosu postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f" ;;
      *)        echo "$0: ignoring $f" ;;
    esac
  done
fi

# Stop PostgreSQL server
gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop

# Start PostgreSQL server in the foreground
exec gosu postgres postgres -D "$PGDATA" -c "config_file=$PGDATA/postgresql.conf"

# Keep the container running
tail -f /dev/null
