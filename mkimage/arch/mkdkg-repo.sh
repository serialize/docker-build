#!/bin/bash

set -e -u -o pipefail
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/lib/common.sh
source $SCRIPT_DIR/lib/filesystem.sh
source $SCRIPT_DIR/lib/repository.sh

OUTPUT_DIR="$SCRIPT_DIR/../../build/arch"
PARENT_DIR=$(create_temp_dir)
TMP_DIR="$PARENT_DIR/temp"
BUILD_DIR="$PARENT_DIR/build"
CACHE_DIR="/var/cache/pacman/pkg"

[ -d "$TMP_DIR" ] || mkdir $TMP_DIR
[ -d "$BUILD_DIR" ] || mkdir $BUILD_DIR
[ -d "$OUTPUT_DIR" ] || mkdir "$OUTPUT_DIR"
#trap "rm -rf '$PARENT_DIR'" KILL TERM EXIT

function handle_package() {
   PACKAGE=$1 FILE=$2 REPO_URL=$3
   if [ -z "$FILE" ]
      then
         debug " ERROR [$PACKAGE]"
         echo "0" && return
   fi
   local TMP_FILE="$TMP_DIR/$FILE" CACHE_FILE="$CACHE_DIR/$FILE"
   local VERSION=$(dump_package_name_version "$PACKAGE" "$FILE")

   #debug "   pkg    [$PACKAGE]   $FILE"
   #debug "   pkg    $FILE"
   #debug "   $FILE"


   LOGSTR="$PACKAGE"
   LENGTH=${#LOGSTR}
   while [ $LENGTH -lt 25 ]
   do
      LOGSTR="$LOGSTR "
      LENGTH=${#LOGSTR}
   done
   VERSION=$(echo $VERSION | gawk '{ print $2 }')
   debug "    $LOGSTR $VERSION"

   [ $(file_exists_not "$FILE") -eq "1" ] && $(download_file "$FILE" "$TMP_DIR" "$REPO_URL")
   [ $(file_exists_cache_only "$FILE") -eq "1" ] && cp "$CACHE_FILE" "$TMP_FILE"
   [ $(file_exists_temp_only "$FILE") -eq "1" ] && cp "$TMP_FILE" "$CACHE_FILE"
   [ -f "$TMP_FILE" ] && echo "$TMP_FILE"

   [ $(function_exists "pre_unpack") -eq "1" ] && $(pre_unpack "$FILE" "$PACKAGE")
   local RESULT=$(uncompress_to_build "$TMP_FILE")
   [ $(function_exists "post_unpack") -eq "1" ] && $(post_unpack "$FILE" "$PACKAGE")
   echo 1
}

$(validate_build_dir "$BUILD_DIR")
$(validate_cache_dir "$CACHE_DIR")

ACTION="filesystem"
[ $# -eq 0 ] || ACTION=$1

debug " "
#debug "-----------------------------------------------------------"
debug "dkg-build [$ACTION] starting"
#debug "-----------------------------------------------------------"

CFG="$SCRIPT_DIR/dkg.conf/$ACTION.dkg"

if [ ! -f "$CFG" ] 
   then
      debug "no config for action [$ACTION]"
      return 
fi

source $CFG

RESULT=""
FILE=""
LIST=()
[ $(function_exists "pre_fetch") == "1" ] && $(pre_fetch "$BUILD_DIR")
if [ ${#CORE_PACKAGES[@]} -gt 0 ] 
   then
      debug " "
      debug " [core] $REPO_CORE_URL"
      RESULT=$(download_list "core" "$REPO_CORE_URL" "$TMP_DIR/..")
      LIST=$(read_list "core" "$TMP_DIR/..")
      for PACKAGE in ${CORE_PACKAGES[*]}; do
         FILE=$(find_in_listfile "$PACKAGE" "core")
         RESULT=$(handle_package "$PACKAGE" "$FILE" "$REPO_CORE_URL")
      done
fi
if [ ${#EXTRA_PACKAGES[@]} -gt 0 ] 
   then 
      debug " "
      debug " [extra] $REPO_EXTRA_URL"
      RESULT=$(download_list "extra" "$REPO_EXTRA_URL" "$TMP_DIR/..")
      LIST=$(read_list "extra" "$TMP_DIR/..")
      for PACKAGE in ${EXTRA_PACKAGES[*]}; do
         FILE=$(find_in_listfile "$PACKAGE" "extra")
         RESULT=$(handle_package "$PACKAGE" "$FILE" "$REPO_EXTRA_URL")
      done
      
      #RESULT=$(iterate_extra_packages "$EXTRA_PACKAGES")
fi
[ $(function_exists "post_fetch") == "1" ] && $(post_fetch "$BUILD_DIR")

DKG=$(compress_build $ACTION)
BCK="$SCRIPT_DIR/dkg"
#cp $DKG "$BCK/$ACTION.dkg.tar.xz"
mv $DKG "$OUTPUT_DIR/$ACTION/assets.dkg.tar.xz"

debug " "
#debug "-----------------------------------------------------------"
debug "dkg-build [$ACTION] finished"
#debug "-----------------------------------------------------------"
debug " "



