#!/bin/sh
. $( dirname "${BASH_SOURCE[0]}" )/config.sh

function docker_image_fullname() {
	printf "%s/%s" $DOCKER_USER $1
}

function docker_image_buildpath() {
	printf "%s/%s" $BUILDS_DIR $1
}