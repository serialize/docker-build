#!/bin/bash

set -e

PG_ALLOW_IP=${PG_ALLOW_IP:-"0.0.0.0/0"}
PG_CONFIG_DIR=/etc/postgres
PG_CONFIG_FILE=$PG_CONFIG_DIR/postgres.conf
PG_HBA_FILE=$PG_CONFIG_DIR/pg_hba.conf
PG_DATA_DIR=/var/lib/postgres/data
PG_RUN_DIR=/run/postgres

pacman -Sy postgresql --noconfirm 
pacman -Scc --noconfirm

chown postgres:postgres /opt/run.sh

if [ ! -d $PG_RUN_DIR ]; then
	mkdir $PG_RUN_DIR
	chown postgres:postgres $PG_RUN_DIR 
	chmod 0700 $PG_RUN_DIR 
fi

if [ ! -d $PG_CONFIG_DIR ]; then
	mkdir $PG_CONFIG_DIR
	chown postgres:postgres $PG_CONFIG_DIR 
	chmod 0700 $PG_CONFIG_DIR 
fi

cat > $PG_CONFIG_FILE <<EOF
data_directory = '$PG_DATA_DIR'
hba_file = '$PG_HBA_FILE'
external_pid_file = '$PG_RUN_DIR/9.3-main.pid'
listen_addresses = '*'	
port = 5432
max_connections = 100
unix_socket_directories = '$PG_RUN_DIR'
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
chown postgres:postgres $PG_CONFIG_FILE 


cat > $PG_HBA_FILE <<EOF
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             $PG_ALLOW_IP               md5
EOF
chown postgres:postgres $PG_HBA_FILE 
