#!/bin/bash

set -e


PGSQL_USER=${PGSQL_USER:-"docker"}
PGSQL_PASS=${PGSQL_PASS:-"docker"}
PGSQL_DB=${PGSQL_DB:-"docker"}
PGSQL_TEMPLATE=${PGSQL_TEMPLATE:-"DEFAULT"}

PGSQL_BIN=/usr/bin/postgres
PGSQL_CONFIG_DIR=/etc/postgres
PGSQL_CONFIG_FILE=$PGSQL_CONFIG_DIR/postgres.conf
PGSQL_HBA_FILE=$PGSQL_CONFIG_DIR/pg_hba.conf
PGSQL_DATA_DIR=/var/lib/postgres/data
PGSQL_RUN_DIR=/run/postgres

PGSQL_SINGLE="$PGSQL_BIN --single --config-file=$PGSQL_CONFIG_FILE"

/usr/bin/initdb -D $PGSQL_DATA_DIR

#if [ ! -d $PGSQL_DATA ]; then
#mkdir -p $PGSQL_DATA
#    chown -R postgres:postgres $PGSQL_DATA
#    sudo -u postgres /usr/lib/postgresql/9.1/bin/initdb -D $PGSQL_DATA
#    ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem $PGSQL_DATA/server.crt
#    ln -s /etc/ssl/private/ssl-cert-snakeoil.key $PGSQL_DATA/server.key
#fi

$PGSQL_SINGLE <<< "CREATE USER $PGSQL_USER WITH SUPERUSER;" > /dev/null
$PGSQL_SINGLE <<< "ALTER USER $PGSQL_USER WITH PASSWORD '$PGSQL_PASS';" > /dev/null
$PGSQL_SINGLE <<< "CREATE DATABASE $PGSQL_DB OWNER $PGSQL_USER TEMPLATE $PGSQL_TEMPLATE;" > /dev/null

exec $PGSQL_BIN --config-file=$PGSQL_CONFIG_FILE

