FROM serialize/base-minimal
MAINTAINER Frank Binder docker@serialize.org

ADD ./opt/init.py /opt/
ADD ./bin/sys-inst /usr/local/bin/
ADD ./bin/sys-inst-clean /usr/local/bin/
ADD ./bin/sys-inst-pkg /usr/local/bin/
ADD ./bin/sys-inst-upd /usr/local/bin/

RUN mkdir /opt/init.d

VOLUME ["/var/log"]
ENTRYPOINT ["/usr/bin/python2"]
CMD ["-u", "/opt/init.py"]