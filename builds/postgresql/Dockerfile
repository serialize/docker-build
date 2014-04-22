FROM serialize/base-pgsql
MAINTAINER Frank Binder docker@serialize.org

ADD ./container/init.sh /opt/init_postgres.sh

RUN chown postgres:postgres /opt/init_postgres.sh && \
	chmod 700 /opt/init_postgres.sh

ADD ./container/postgres.ini /etc/supervisor.d/
