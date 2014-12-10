#!/bin/sh
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
docker build -t "serialize/debian:jessie" $DIR
