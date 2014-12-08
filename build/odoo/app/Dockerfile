FROM serialize/odoo-base
MAINTAINER Frank Binder <docker@serialize.org>

RUN wget -nv -O- https://github.com/odoo/odoo/archive/8.0.tar.gz \
	| tar xz --xform s,^odoo-8.0,odoo, -C /opt && cd /opt/odoo \
	&& pip install -e .

USER odoo
EXPOSE 8069 8072
ENTRYPOINT ["/opt/odoo/openerp-server"]
CMD ["-c" "/etc/odoo/odoo-server.conf"]

