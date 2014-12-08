FROM serialize/debian:jessie
MAINTAINER Frank Binder <docker@serialize.org>

RUN echo deb http://ftp.debian.org/debian experimental main > /etc/apt/sources.list.d/experimental.list \
    && apt-get update \
    && apt-get -t experimental install -y --no-install-recommends postgresql \
	&& sed -i "s|/var/run/postgresql/9.4-main.pg_stat_tmp|/var/run/postgresql|g" /etc/postgresql/9.4/main/postgresql.conf

ENV PGDATA /var/lib/postgresql/9.4/main
USER postgres
VOLUME ["/var/lib/postgresql","/var/log/postgresql","/etc/postgresql"]
EXPOSE 5432
ENTRYPOINT ["/usr/lib/postgresql/9.4/bin/postgres"]
CMD ["-D","/var/lib/postgresql/9.4/main/","-c","config_file=/etc/postgresql/9.4/main/postgresql.conf"]

