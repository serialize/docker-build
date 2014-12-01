FROM serialize/debian:jessie
MAINTAINER Frank Binder <docker@serialize.org>

RUN echo deb http://ftp.debian.org/debian experimental main > /etc/apt/sources.list.d/experimental.list \
    && apt-get update \
    && apt-get -t experimental install -y --no-install-recommends postgresql

ADD ./asset/init.sh /init
ENV PGDATA /var/lib/postgresql/data
VOLUME ["/var/lib/postgresql/data","/var/log/postgresql","/etc/postgresql"]
EXPOSE 5432
CMD ["/init"]

