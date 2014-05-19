FROM serialize/arch-minimal
MAINTAINER Frank Binder docker@serialize.org

ADD opt/ /opt/

RUN chmod 0700 /opt/init.sh /opt/run.sh && \
	/opt/init.sh && \
	rm /opt/init.sh  

USER postgres

EXPOSE 5432

VOLUME  ["/etc/postgres", "/var/log/postgres", "/var/lib/postgres"]

CMD ["/opt/run.sh"] 
