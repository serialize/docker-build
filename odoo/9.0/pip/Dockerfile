FROM serialize/odoo:9.0-deps
MAINTAINER Frank Binder <info@sez23.net>

RUN apt-get update -qq &&  \
	apt-get upgrade -qq -y && \
	apt-get install \
		libxml2-dev \
		libxslt1-dev \
		libldap2-dev \
		libsasl2-dev \
		libssl-dev \
		libjpeg-dev \
		python-dev \
		python-pip \
		build-essential \
		python -y && \
	easy_install --upgrade pip && \
	rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

COPY requirements.txt /opt/release/requirements.txt

RUN pip install -r /opt/release/requirements.txt