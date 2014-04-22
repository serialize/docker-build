FROM serialize/base-minimal
MAINTAINER Frank Binder docker@serialize.org

ADD ./container/init.py /opt/

RUN mkdir /opt/init.d

VOLUME ["/var/log"]
ENTRYPOINT ["/usr/bin/python2"]
CMD ["-u", "/opt/init.py"]