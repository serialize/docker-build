#!/bin/bash

DEFAULT_CACHE_DIR=/tmp/mkimage/cache
DEFAULT_BUILD_DIR=/tmp/mkimage/build
DEFAULT_TMP_DIR=/tmp/mkimage/temp

CACHE_DIR="$DEFAULT_CACHE_DIR"
BUILD_DIR="$DEFAULT_BUILD_DIR"
TMP_DIR="$DEFAULT_TMP_DIR"

# Rebuild dev nodes
function rebuild_dev_nodes() {
   local BUILD=$1
   DEV=$BUILD/dev
   rm -rf $DEV
   mkdir -p $DEV
   mknod -m 666 $DEV/null c 1 3
   mknod -m 666 $DEV/zero c 1 5
   mknod -m 666 $DEV/random c 1 8
   mknod -m 666 $DEV/urandom c 1 9
   mkdir -m 755 $DEV/pts
   mkdir -m 1777 $DEV/shm
   mknod -m 666 $DEV/tty c 5 0
   mknod -m 600 $DEV/console c 5 1
   mknod -m 666 $DEV/tty0 c 4 0
   mknod -m 666 $DEV/full c 1 7
   mknod -m 600 $DEV/initctl p
   mknod -m 666 $DEV/ptmx c 5 2
   ln -sf /proc/self/fd $DEV/fd
}

function build_etc() {
   local BUILD=$1
   echo "root:x:0:0:root:/root:/bin/bash" > "$BUILD/etc/passwd" 
   echo 'root:$1$GT9AUpJe$oXANVIjIzcnmOpY07iaGi/:14657::::::' > "$BUILD/etc/shadow"
   touch "$BUILD/etc/group"
   echo "arch-filesystem" > "$BUILD/etc/hostname"
   test -e "$BUILD/etc/mtab" || echo "rootfs / rootfs rw 0 0" > "$BUILD/etc/mtab"
   cp "/etc/resolv.conf" "$BUILD/etc/resolv.conf"
}

function validate_build_dir() {
   local BUILD=$1
   [ -d "$BUILD" ] && rm -rf $BUILD
   mkdir "$BUILD"
}

function validate_cache_dir() {
   local CACHE=$1
   [ -d "$CACHE" ] || mkdir "$CACHE"
}

function file_exists() {
   local FILE=$1 DIR=$2
   [ -f "$DIR/$FILE" ] && echo "1" || echo "0"
}

function temp_file_exists() {
   local FILE=$1
   echo $(file_exists "$FILE" "$TMP_DIR")
}

function cache_file_exists() {
   local FILE=$1
   echo $(file_exists "$FILE" "$CACHE_DIR")
}

function create_temp_dir() {
   local TEMP="$(mktemp -d)"
   echo $TEMP
}

function file_exists_temp_only() {
   local FILE=$1
   TEMP_CHECK=$(temp_file_exists "$FILE")
   CACHE_CHECK=$(cache_file_exists "$FILE")
   RESULT="0"
   [[ "$TEMP_CHECK" == "1" ]] && [[ "$CACHE_CHECK" != "1" ]] && RESULT="1"
   echo $RESULT
   #   then
   #      RESULT="1" 
   #fi
}

function file_exists_cache_only() {
   local FILE=$1
   TEMP_CHECK=$(temp_file_exists "$FILE")
   CACHE_CHECK=$(cache_file_exists "$FILE")
   RESULT="0"
   [[ "$TEMP_CHECK" != "1" ]] && [[ "$CACHE_CHECK" == "1" ]] && RESULT="1"
   echo $RESULT
}

function file_exists_cache_and_temp() {
   local FILE=$1
   TEMP_CHECK=$(temp_file_exists "$FILE")
   CACHE_CHECK=$(cache_file_exists "$FILE")
   RESULT="0"
   [[ "$TEMP_CHECK" == "1" ]] && [[ "$CACHE_CHECK" == "1" ]] && RESULT="1"
   echo $RESULT
}

function file_exists_not() {
   local FILE=$1
   TEMP_CHECK=$(temp_file_exists "$FILE")
   CACHE_CHECK=$(cache_file_exists "$FILE")
   RESULT="0"
   [[ "$TEMP_CHECK" != "1" ]] && [[ "$CACHE_CHECK" != "1" ]] && RESULT="1"
   echo $RESULT
}


function create_temp_dir_bck() {
   local TEMP="$(mktemp -d)"
   TMP_DIR="$TEMP/temp"
   debug "Temp Directory:  $TMP_DIR" 
   mkdir $TMP_DIR
   debug "Temp Directory created"
   BUILD_DIR="$TEMP/build"
   debug "Build Directory: $BUILD_DIR" 
   mkdir $BUILD_DIR
   debug "Build Directory created"
   trap "rm -rf '$TEMP'" KILL TERM EXIT
}

function copy_to_cache() {
   local SOURCE=$1
   local DEST="$CACHE_DIR/"
   if [ -f $SOURCE ];then
      cp $SOURCE $DEST
   fi    
}

function copy_from_cache() {
   local FILE=$1
   local SOURCE="$CACHE_DIR/$FILE"
   local DEST="$TMP_DIR/"
   if [ -f $SOURCE ];then
      cp $SOURCE $DEST
   fi    
}

function compress() {
   local FILE=$1 SOURCE=$2
   tar --xz -f "$FILE" --numeric-owner -C "$SOURCE" -c .
}

function compress_build() {
   local NAME=$1
   local FILE="$TMP_DIR/$NAME.dkg.tar.xz"
   $(compress "$FILE" "$BUILD_DIR")
   echo $FILE
}

# Extract FILEPATH gz/xz archive to DEST directory
function uncompress() {
   local FILEPATH=$1 DEST=$2

   case "$FILEPATH" in
      *.gz) res=$(tar xzf "$FILEPATH" -C "$DEST" --exclude="/usr/share/man" >&2);;
      *.xz) res=$(xz -dc "$FILEPATH" | tar x -C "$DEST" --exclude="/usr/share/man" 2> >(grep -v 'SCHILY.fflags' >&2));;
      *) debug "Error: unknown package format: $FILEPATH"
         return 1;;
   esac
   #*.xz) res=$(xz -dc "$FILEPATH" | tar x -C "$DEST" --exclude="/usr/share/man" >&2);;
}  

function uncompress_to_build() {
   local FILE=$1 SOURCE="$TMP_DIR/$FILE"
   $(uncompress "$SOURCE" "$BUILD_DIR")
   local RM="$BUILD_DIR/.INSTALL"
   [ -e $RM ] && rm $RM
   RM="$BUILD_DIR/.MTREE"
   [ -e $RM ] && rm $RM
   RM="$BUILD_DIR/.PKGINFO"
   [ -e $RM ] && rm $RM
}

