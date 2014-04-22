#!/bin/bash

export DOCKER_USER=serialize
export DOCKER_MAINTAINER="Frank Binder docker@serialize.org"
export DOCKER_BIN=/usr/bin/docker

export SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ROOT_DIR=$(dirname $SCRIPTS_DIR)
export BUILDS_DIR=$ROOT_DIR/builds

export DOCKERFILE_DEFAULT_PARENT=base-default