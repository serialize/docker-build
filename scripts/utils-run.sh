#!/bin/sh
. $( dirname "${BASH_SOURCE[0]}" )/config.sh
. $( dirname "${BASH_SOURCE[0]}" )/utils-common.sh

function docker_run_shell() {
	image=$(docker_image_fullname $1)
	cmd=$("$DOCKER_BIN run -i -t --entrypoint=\"/bin/bash\" $image -i")
	$cmd
}

function docker_run_exec() {
	image=$(docker_image_fullname $1)
	cmd=$("$DOCKER_BIN run -i -t --entrypoint=\"/bin/bash\" $image $2")
	exec $cmd
}

function docker_run_map_volume() {
	echo ""
}