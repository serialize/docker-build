FROM serialize/base-default
MAINTAINER Frank Binder docker@serialize.org

RUN pacman -Sy --noconfirm  postgresql && \
	pacman -Scc --noconfirm

ADD ./container/init.sh /opt/init_postgres_main.sh

RUN mkdir /run/postgresql && \
	chown postgres:postgres /run/postgresql && \
	chown postgres:postgres /opt/init_postgres_main.sh && \
	su - postgres -c "/opt/init_postgres_main.sh"

EXPOSE 5432
VOLUME ["/var/lib/postgres/"]		