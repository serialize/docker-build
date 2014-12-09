#!/bin/bash

set -e -u -o pipefail

DEFAULT_ARCH=`uname -m`
DEFAULT_REPO_URL="http://mirrors.kernel.org/archlinux"

ARCH="$DEFAULT_ARCH"
REPO_URL="$DEFAULT_REPO_URL"
REPO_CORE_URL="$REPO_URL/core/os/$ARCH"
REPO_EXTRA_URL="$REPO_URL/extra/os/$ARCH"

REPO_CORE_PKGLIST=()
REPO_EXTRA_PKGLIST=()

# Extract href attribute from HTML link
function extract_href() { 
    sed -n '/<a / s/^.*<a [^>]*href="\([^\"]*\)".*$/\1/p'; 
}

function dump_package_name_version() {
   local PACKAGE=$1 FILE=$2
   local FILENAME="$(basename $FILE)"
   FILENAME="${FILENAME%-*}"
   local LEN="${#PACKAGE} + 1"
   local VERSION="${FILENAME:$LEN}"
   echo "$PACKAGE $VERSION"
}

# Simple wrapper around wget
function fetch() { 
   wget -c --passive-ftp --quiet "$@"; 
}

function file_from_pkglist() {
   local LIST=$1 PACKAGE=$2
   local FILE=$(echo "$LIST" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$")
   test "$FILE" || { debug "Error: cannot find package: $PACKAGE"; return 1; }
   echo "$FILE"
}

function fetch_pkglist() {
   local REPO=$1 
   # Force trailing '/' needed by FTP servers.
   fetch -O - "$REPO/" | extract_href | awk -F"/" '{print $NF}' | sort -rn ||
      { debug "Error: cannot fetch packages list: $REPO"; return 1; }
}


function get_file() {
   local PACKAGE=$1 LIST=$2
   echo $(grep_file "$LIST" "$PACKAGE")
}

function grep_file() {
   local REPO_PACKAGES=$1 PACKAGE=$2
   local FILE=$(echo "$REPO_PACKAGES" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$")
}
function find_in_listfile_bck() {
   local FILE=$1 PACKAGE=$2
   local RESULT=$(cat "$FILE" | grep "$PACKAGE" | grep -v "xz.sig")
   echo "$RESULT"
}
function find_in_listfile2() {
   local FILE=$1 PACKAGE=$2
   local RESULT=$(cat "$FILE" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$")
   echo "$RESULT"
}

function find_in_listfile() {
   local PACKAGE=$1 REPO_NAME=$2 
   local FILE="$TMP_DIR/../$REPO_NAME.pkg.list"
   local RESULT=$(cat "$FILE" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$")
   echo "$RESULT"
}

function find_in_list() {
   local LIST=$1 PACKAGE=$2
   local FILE=$(echo "${LIST[*]}" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$")
   echo $FILE
}

function search_file() {
   local REPO_LIST=$1 FILE=$2
   echo $(echo "$REPO_LIST" | grep -m1 "$FILE")
}
function search_package() {
   local REPO_LIST=$1 PACKAGE=$2
   echo $(echo "$REPO_LIST" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$")
}
function download_file() {
   local FILE=$1 DEST=$2 REPO_URL=$3 
   [ ! -f "$DEST/$FILE" ] && fetch -O "$DEST/$FILE" "$REPO_URL/$FILE"
}
function download_package() {
   local PACKAGE=$1 DEST=$2 REPO_NAME=$3 REPO_URL=$4
   local FILE=$(find_in_listfile "$PACKAGE" "$REPO_NAME")
   $(download_file "$FILE" "$DEST" "$REPO_URL")
}
#function download_package() {
#   local FILE=$1 SOURCE="$REPO/$FILE" DEST="$TMP_DIR/$FILE"
#   if [ ! -f $DEST ];then
#      fetch -O "$DEST" "$SOURCE"
#      copy_to_cache "$DEST"      
#   fi
#}
#function download_core_package() {
#   local PACKAGE=$1 DEST=$2
#   local FILE=$(get_core_file "$PACKAGE")
#   $(download_file "$FILE" "$DEST" "$REPO_CORE_URL")
#}
#function download_extra_package() {
#   local PACKAGE=$1 DEST=$2
#   local FILE=$(get_extra_file "$PACKAGE")
#   $(download_file "$FILE" "$DEST" "$REPO_EXTRA_URL")
#}

function download_list() {
   local REPO_NAME=$1 REPO_URL=$2 DEST=$3
   local FILE="$DEST/$REPO_NAME.pkg.list"
   local LIST=$(fetch_pkglist "$REPO_URL")
   [ -f "$FILE" ] && rm $FILE
   for PKG in $LIST; do
      echo $PKG >> "$FILE"
   done
   echo "$FILE"
}
function read_list() {
   local REPO_NAME=$1 SOURCE=$2
   local FILE="$SOURCE/$REPO_NAME.pkg.list"
   echo $(cat $FILE)
}


