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


pacman -Sy postgresql --noconfirm 
pacman -Scc --noconfirm

chown postgres:postgres /opt/run.sh

mkdir $PGSQL_RUN_DIR
chown postgres:postgres $PGSQL_RUN_DIR 
chmod 0700 $PGSQL_RUN_DIR 

mkdir $PGSQL_CONFIG_DIR
chown postgres:postgres $PGSQL_CONFIG_DIR 
chmod 0700 $PGSQL_CONFIG_DIR 

cat > $PGSQL_CONFIG_FILE <<EOF
data_directory = '$PGSQL_DATA_DIR'
hba_file = '$PGSQL_HBA_FILE'
external_pid_file = '$PGSQL_RUN_DIR/9.3-main.pid'
listen_addresses = '*'	
port = 5432
max_connections = 100
unix_socket_directories = '$PGSQL_RUN_DIR'
shared_buffers = 128MB
log_line_prefix = '%t '
log_timezone = 'UTC'
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'C'
lc_monetary = 'C'
lc_numeric = 'C'
lc_time = 'C'
default_text_search_config = 'pg_catalog.english'
EOF
chown postgres:postgres $PGSQL_CONFIG_FILE 


cat > $PGSQL_HBA_FILE <<EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               md5
EOF
chown postgres:postgres $PGSQL_HBA_FILE 
