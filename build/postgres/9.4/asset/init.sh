#!/bin/sh
pg_ctlcluster 9.4 main start


# Start PostgreSQL
echo "Starting PostgreSQL..."
su -c '/usr/lib/postgresql/9.4/bin/postgres -D /var/lib/postgresql/data -c config_file=/etc/postgresql/postgresql.conf' postgres

