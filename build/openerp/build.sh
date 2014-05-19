#!/bin/bash
docker build -t serialize/openerp-volume volume
docker build -t serialize/openerp-db db
docker build -t serialize/openerp-web web
