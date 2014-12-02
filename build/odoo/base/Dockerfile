FROM serialize/python:2.7
MAINTAINER Frank Binder <docker@serialize.org>

RUN apt-get update \
	&& apt-get install -y --no-install-recommends python-geoip python-gevent \
		python-ldap python-lxml python-markupsafe python-pil \
		python-psutil python-psycopg2 python-pychart python-pydot \
		python-reportlab python-simplejson python-yaml wget wkhtmltopdf \
	&& adduser --system --group --home /var/lib/odoo --shell /bin/bash odoo 
