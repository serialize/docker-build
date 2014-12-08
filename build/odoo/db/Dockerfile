FROM serialize/postgres:9.4
MAINTAINER Frank Binder <docker@serialize.org>

RUN /etc/init.d/postgresql start \
	&& psql --command "CREATE USER odoo WITH SUPERUSER PASSWORD 'odoo';"
