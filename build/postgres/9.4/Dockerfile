FROM serialize/debian:jessie
MAINTAINER Frank Binder <docker@serialize.org>

RUN echo deb http://ftp.debian.org/debian experimental main > /etc/apt/sources.list.d/experimental.list \
    && apt-get update \
    && apt-get -t experimental install -y --no-install-recommends postgresql \
    && pg_ctlcluster 9.4 main start

ENV PGDATA /var/lib/postgresql/data
VOLUME ["/var/lib/postgresql/data"]
EXPOSE 5432

