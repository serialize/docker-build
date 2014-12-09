#!/bin/bash

set -e -u -o pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/utils/include.sh

OUTPUT_DIR="$SCRIPT_DIR/../../build/base/arch"
PARENT_DIR=$(create_temp_dir)
TMP_DIR="$PARENT_DIR/temp"
BUILD_DIR="$PARENT_DIR/build"
CACHE_DIR="/var/cache/pacman/pkg"

[ -d "$TMP_DIR" ] || mkdir $TMP_DIR
[ -d "$BUILD_DIR" ] || mkdir $BUILD_DIR
[ -d "$OUTPUT_DIR" ] || mkdir "$OUTPUT_DIR"
trap "rm -rf '$PARENT_DIR'" KILL TERM EXIT

$(validate_build_dir "$BUILD_DIR")
$(validate_cache_dir "$CACHE_DIR")

ACTION="filesystem"
[ $# -eq 0 ] || ACTION=$1

debug " "
#debug "-----------------------------------------------------------"
debug "dkg [$ACTION] creation starting"
#debug "-----------------------------------------------------------"
debug " "

case $ACTION in
   glibc) 
      $(fetch_core_packages "linux-api-headers tzdata glibc")
      ;;
   bash) 
      $(fetch_core_packages "acl attr curl expat e2fsprogs ncurses readline bash shadow")
      ;;
   perl) 
      $(fetch_core_packages "perl")
      ;;
   pacman) 
      $(fetch_core_packages "archlinux-keyring bzip2 keyutils libarchive gpgme libassuan krb5 libgpg-error libssh2 openssl pacman pacman-mirrorlist xz zlib")
      ;;
   *)
      $(fetch_core_packages "iana-etc filesystem")
      $(rebuild_dev_nodes "$BUILD_DIR")
      $(build_etc "$BUILD_DIR")
      ACTION="filesystem"
      ;;
esac

DKG=$(compress_build $ACTION)
mv $DKG "$OUTPUT_DIR/$ACTION/assets.dkg.tar.xz"

debug " "
#debug "-----------------------------------------------------------"
debug "dkg [$ACTION] creation finished"
#debug "-----------------------------------------------------------"
debug " "



