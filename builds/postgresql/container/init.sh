#!/bin/sh
PG_DATA="/var/lib/postgres/data"

PG_USER=${PG_USER:-"docker"}
PG_PASSWORD=${PG_PASSWORD:-"docker"}
PG_DB=${PG_DB:-"docker"}

  # Start the process of initialising the user and database
  (
    while ! (echo "" | /usr/bin/psql -U postgres 2>&1 > /dev/null); do sleep 1; done
    echo "PostgreSQL Is up, initialising..."
	RESULT=$(psql -tAc "SELECT 1 FROM pg_database WHERE datname='${PG_USER}_${PG_DB}'")
	
	if [[ -z $RESULT ]]
	then
	    # Create the user and database
	    echo "CREATE USER \"${PG_USER}\" WITH CREATEDB PASSWORD '${PG_PASSWORD}';" \
	         "CREATE DATABASE \"${PG_USER}_${PG_DB}\" WITH OWNER \"${PG_USER}\";" \
		         | psql
	fi

  ) &

exec /usr/bin/postgres -D "${PG_DATA}" "$@"
