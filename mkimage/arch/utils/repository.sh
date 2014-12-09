#!/bin/bash

set -e -u -o pipefail

DEFAULT_ARCH=`uname -m`
DEFAULT_REPO_URL="http://mirrors.kernel.org/archlinux"

ARCH="$DEFAULT_ARCH"
REPO_URL="$DEFAULT_REPO_URL"
REPO_CORE_URL="$REPO_URL/core/os/$ARCH"
REPO_EXTRA_URL="$REPO_URL/extra/os/$ARCH"

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

function download_package() {
   local FILE=$1 SOURCE="$REPO/$FILE" DEST="$TMP_DIR/$FILE"
   if [ ! -f $DEST ];then
      fetch -O "$DEST" "$SOURCE"
      copy_to_cache "$DEST"      
   fi
}

function fetch_packages() {
   local PACKAGES=$1 REPO=$2
   #debug "fetching package list"
   local LIST=$(fetch_pkglist $REPO)
   for PACKAGE in $PACKAGES; do
      local FILE=$(file_from_pkglist "$LIST" "$PACKAGE")      
      debug "fetching $FILE"
      $(copy_from_cache "$FILE")
      $(download_package "$FILE")
      $(uncompress_to_build "$FILE")
      #VERSION=$(dump_package_name_version "$PACKAGE" "$FILE")
      #echo $VERSION >> "$BUILD_DIR/.PKGLIST"
  done
}
function fetch_core_packages() {
   local PACKAGES=$1
   $(fetch_packages "$PACKAGES" "$REPO_CORE_URL")
}
function fetch_extra_packages() {
   local PACKAGES=$1
   $(fetch_packages "$PACKAGES" "$REPO_EXTRA_URL")
}

