#!/bin/bash
docker run -name sez-openerp-volume serialize/openerp-volume true
docker run -name sez-openerp-db serialize/openerp-db true
docker run -name sez-openerp-web serialize/openerp-web true
