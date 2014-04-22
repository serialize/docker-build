#!/bin/sh
PG_DATA="/var/lib/postgres/data"

if [ ! -f "$PG_DATA/pg_hba.conf" ]; then
	initdb -D "${PG_DATA}"
	echo "host all all 0.0.0.0/0 md5" >> "${PG_DATA}/pg_hba.conf"
	echo "host all all ::/0 md5" >> "${PG_DATA}/pg_hba.conf"
	echo "listen_addresses = '*'" >> "${PG_DATA}/postgresql.conf"
fi

