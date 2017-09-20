FROM debian:jessie
MAINTAINER Frank Binder <info@sez23.net>

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        adduser \
        ca-certificates \
        curl \
        cups \
        node-less \
        postgresql-client \
        python \
        python-babel \
        python-dateutil \
        python-decorator \
        python-docutils \
        python-feedparser \
        python-gevent \
        python-imaging \
        python-jinja2 \
        python-ldap \
        python-libxslt1 \
        python-lxml \
        python-mako \
        python-mock \
        python-openid \
        python-passlib \
        python-pip \
        python-psutil \
        python-psycopg2 \
        python-pychart \
        python-pydot \
        python-pyparsing \
        python-pypdf \
        python-renderpm \
        python-reportlab \
        python-requests \
        python-suds \
        python-support \
        python-tz \
        python-vatnumber \
        python-vobject \
        python-watchdog \
        python-werkzeug \
        python-xlwt \
        python-yaml
    && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
    && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
    && dpkg --force-depends -i wkhtmltox.deb \
    && apt-get -y install -f --no-install-recommends \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
    && pip install psycogreen==1.0