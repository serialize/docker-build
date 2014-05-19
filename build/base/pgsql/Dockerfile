FROM serialize/arch-minimal
MAINTAINER Frank Binder docker@serialize.org

RUN pacman -Sy postgresql --noconfirm && \
    pacman -Scc --noconfirm
    
ADD opt/init.sh /opt/init

#USER postgres

#EXPOSE 5432

#VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

#CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"] 
