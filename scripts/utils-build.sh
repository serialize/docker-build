#!/bin/sh
. $( dirname "${BASH_SOURCE[0]}" )/config.sh
. $( dirname "${BASH_SOURCE[0]}" )/utils-common.sh

function docker_build_init() {
	name=$1
	path=$BUILDS_DIR/$name
	
	if [ -d $path ]; then
		echo "ERROR: build directory exists ($path)"
	else
		mkdir $path
		path=$path/Dockerfile
		_dockerfile_user_input
		_dockerfile_get_content >> $path
		
		
	fi
}

function docker_build() {
	build_name=$(docker_image_fullname $1)
	build_path=$(docker_image_buildpath $1)
	echo ""
	echo "#-----------------------------------------------------------------------------------"
	echo "# building image..."
	printf '# name:   %s\n' $build_name 
	printf '# path:   %s\n' $build_path 
	echo "#-----------------------------------------------------------------------------------"
	$DOCKER_BIN build -t $build_name $build_path
}

function _dockerfile_user_input() {
	read -p "Parent image [base-default]: " img_parent
	if [ -z $img_parent ]; then
		export DOCKERFILE_PARENT=$DOCKERFILE_DEFAULT_PARENT
	fi

	read -p "Package(s) to be installed: " img_packages
	if [ ! -z $img_packages ]; then
		export DOCKERFILE_PACKAGES=$img_packages
	fi

	read -p "Port(s) to expose: " img_expose
	if [ ! -z $img_expose ]; then
		export DOCKERFILE_EXPOSE=$img_expose
	fi
	
	read -p "User assignment: " img_user
	if [ ! -z $img_user ]; then
		export DOCKERFILE_USER=$img_user
	fi
	
	read -p "Image volume: " img_volume
	if [ ! -z $img_volume ]; then
		export DOCKERFILE_VOLUME=$img_volume
	fi
																
}

function _dockerfile_get_content() {
	if [ -z $DOCKERFILE_PARENT ]; then
		DOCKERFILE_PARENT=base-default
	fi
	echo "FROM $DOCKER_USER/$DOCKERFILE_PARENT"
	echo "MAINTAINER $DOCKER_MAINTAINER"
	echo ""
	if [ ! -z $DOCKERFILE_PACKAGES ]; then
		echo "RUN pacman -Sy --noconfirm $DOCKERFILE_PACKAGES && \\"
		echo "    pacman -Scc --noconfirm"
		echo ""
	fi
	if [ ! -z $DOCKERFILE_EXPOSE ]; then
		echo "EXPOSE $DOCKERFILE_EXPOSE"
		echo ""
	fi
	if [ ! -z $DOCKERFILE_USER ]; then
		echo "USER $DOCKERFILE_USER"
		echo ""
	fi
	if [ ! -z $DOCKERFILE_VOLUME ]; then
		echo "VOLUME $DOCKERFILE_VOLUME"
		echo ""
	fi
}