#!/bin/bash

set -e


PG_USER=${PG_USER:-"docker"}
PG_PASS=${PG_PASS:-"docker"}
PG_DB=${PG_DB:-"docker"}
PG_TEMPLATE=${PG_TEMPLATE:-"DEFAULT"}

PG_BIN=/usr/bin/postgres
PG_CONFIG_DIR=/etc/postgres
PG_CONFIG_FILE=$PG_CONFIG_DIR/postgres.conf
PG_DATA_DIR=/var/lib/postgres/data

PG_BIN_SINGLE="$PG_BIN --single --config-file=$PG_CONFIG_FILE"

if [ ! -f $PG_DATA_DIR/PG_VERSION ]; then
	/usr/bin/initdb -D $PG_DATA_DIR
	$PG_BIN_SINGLE <<< "CREATE USER $PG_USER WITH SUPERUSER;" > /dev/null
	$PG_BIN_SINGLE <<< "ALTER USER $PG_USER WITH PASSWORD '$PG_PASS';" > /dev/null
	$PG_BIN_SINGLE <<< "CREATE DATABASE $PG_DB OWNER $PG_USER TEMPLATE $PG_TEMPLATE;" > /dev/null
fi

exec $PG_BIN --config-file=$PG_CONFIG_FILE

