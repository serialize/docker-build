#!/bin/sh
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ID=$(docker build -t "serialize/debian:wheezy" $DIR)
docker tag $ID serialize/debian:latest
