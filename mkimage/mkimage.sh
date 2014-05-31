#!/bin/bash

set -e -u -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_ARCH=`uname -m`
DEFAULT_REPO_URL="http://mirrors.kernel.org/archlinux"
DEFAULT_CACHE_DIR=$SCRIPT_DIR/cache
DEFAULT_BUILD_DIR=$SCRIPT_DIR/build

ARCH="$DEFAULT_ARCH"
REPO_URL="$DEFAULT_REPO_URL"
REPO_CORE_URL="$REPO_URL/core/os/$ARCH"
REPO_EXTRA_URL="$REPO_URL/extra/os/$ARCH"
CACHE_DIR="$DEFAULT_CACHE_DIR"
BUILD_DIR="$DEFAULT_BUILD_DIR"
TMP_DIR="/tmp/"

BASH_PACKAGES=(
   iana-etc filesystem linux-api-headers tzdata glibc ncurses readline bash
)
PACMAN_PACKAGES=(
   acl archlinux-keyring attr krb5 bzip2 curl expat gpgme libarchive e2fsprogs keyutils perl
   libassuan libgpg-error libssh2 lzo2 openssl pacman pacman-mirrorlist xz zlib shadow 
)
EXTRA_PACKAGES=( haveged )

# Output to standard error
function stderr() { 
   echo "$@" >&2; 
}

# Output debug message to standard error
function debug() { 
   stderr "--- $@"; 
}

# Output to standard error
function stderr-n() { 
   echo -n "$@" >&2; 
}

# Output debug message to standard error
function debug-n() { 
   stderr-n "$@"; 
}

# Extract href attribute from HTML link
function extract_href() { 
   sed -n '/<a / s/^.*<a [^>]*href="\([^\"]*\)".*$/\1/p'; 
}

# Simple wrapper around wget
function fetch() { 
   wget -c --passive-ftp --quiet "$@"; 
}

# Extract FILEPATH gz/xz archive to DEST directory
function uncompress() {
  local FILEPATH=$1 DEST=$2
  
  case "$FILEPATH" in
    *.gz) res=$(tar xzf "$FILEPATH" -C "$DEST" --exclude="/usr/share/man" >&2);;
    *.xz) res=$(xz -dc "$FILEPATH" | tar x -C "$DEST" --exclude="/usr/share/man" >&2);;
    *) debug "Error: unknown package format: $FILEPATH"
       return 1;;
  esac
}  

function fetch_packages_list() {
  local REPO=$1 
  
  # Force trailing '/' needed by FTP servers.
  fetch -O - "$REPO/" | extract_href | awk -F"/" '{print $NF}' | sort -rn ||
    { debug "Error: cannot fetch packages list: $REPO"; return 1; }
}

function _fetch_packages() {
  debug " fetching package list..."
  debug " "
  local PACKAGES=$1 REPO=$2
  
  local LIST=$(fetch_packages_list $REPO)
  for PACKAGE in $PACKAGES; do
    debug-n "--- "  
    local FILE=$(echo "$LIST" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$")
    test "$FILE" || { debug "Error: cannot find package: $PACKAGE"; return 1; }
    debug-n " $FILE --> "
       
    local TMP_PATH="$TMP_DIR/$FILE" CACHE_PATH="$CACHE_DIR/$FILE" REPO_URI="$REPO/$FILE"
    if [ -f $CACHE_PATH ];then
       debug-n "[cache]" # $REPO/$FILE"
       cp $CACHE_PATH $TMP_DIR/
    fi    
    if [ ! -f $TMP_PATH ];then
       debug-n "[repo]" # $REPO/$FILE"
       fetch -O "$TMP_PATH" "$REPO_URI"
       cp $TMP_PATH $CACHE_DIR/
    fi
    stderr " "
    uncompress "$TMP_PATH" "$BUILD_DIR"
  done
  #rm_man "$BUILD_DIR"
}

function fetch_version() {
   local PACKAGES=$1 PKGDIR=$2 IMGNAME=$3
   for PACKAGE in $PACKAGES; do
      for file in $PKGDIR/$PACKAGE*; do
         name=$(basename $file)
         name=${name%-*}
         len="${#PACKAGE} + 1"
         ver=${name:$len}
         echo "$IMGNAME $PACKAGE $ver"
      done
   done

}

function docker_test_package() {
   local package=$1 name=$2
   cat $package | docker import - $name
   CDI=$(docker run -t -i $name echo success)
   
}

function docker_build() {
   local path=$1 name=$2
   docker build -t $name $path/.
}

function prepare_image() {
   
   debug "-------------------------------------------------------------------"
   debug " preparing image..."  
   debug "-------------------------------------------------------------------"
          
   while getopts "a:r" ARG; do
      case "$ARG" in
         a) ARCH=$OPTARG;;
         r) REPO_URL=$OPTARG;;
         d) BUILD_DIR=$OPTARG;;
      esac
   done
   
   [ -d "$BUILD_DIR" ] && rm -rf $BUILD_DIR
   mkdir "$BUILD_DIR"
   [ -d "$CACHE_DIR" ] || mkdir "$CACHE_DIR"
   TMP_DIR=$(mktemp -d)
   trap "rm -rf '$TMP_DIR'" KILL TERM EXIT

   debug " arch:                $ARCH"
   debug " build directory:     $BUILD_DIR"
   debug " cache directory:     $CACHE_DIR"
   debug " temporary directory: $TMP_DIR"
   debug " "
   debug " core repository:     $REPO_CORE_URL"
   _fetch_packages "${BASH_PACKAGES[*]} ${PACMAN_PACKAGES[*]}" "$REPO_CORE_URL"
      
   debug " "
   debug " extra repository:     $REPO_EXTRA_URL"
   _fetch_packages "${EXTRA_PACKAGES[*]}" "$REPO_EXTRA_URL"
   
}

function configure_image() {
   
   debug "-------------------------------------------------------------------"
   debug " configure image..."  
   debug "-------------------------------------------------------------------"
   debug " creating config files"
   
   mkdir -p "$BUILD_DIR/dev"
   echo "root:x:0:0:root:/root:/bin/bash" > "$BUILD_DIR/etc/passwd" 
   echo 'root:$1$GT9AUpJe$oXANVIjIzcnmOpY07iaGi/:14657::::::' > "$BUILD_DIR/etc/shadow"
   touch "$BUILD_DIR/etc/group"
   echo "arch-minimal" > "$BUILD_DIR/etc/hostname"
  
   debug " rebuilding dev"
   test -e "$BUILD_DIR/etc/mtab" || echo "rootfs / rootfs rw 0 0" > "$BUILD_DIR/etc/mtab"
   # udev doesn't work in containers, rebuild /dev
   DEV=$BUILD_DIR/dev
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

   debug " configure dns"
   cp "/etc/resolv.conf" "$BUILD_DIR/etc/resolv.conf"
   debug " configure pacman"
   sed -i "s/^[[:space:]]*\(CheckSpace\)/# \1/" "$BUILD_DIR/etc/pacman.conf"
   sed -i "s/^[[:space:]]*SigLevel[[:space:]]*=.*$/SigLevel = Never/" "$BUILD_DIR/etc/pacman.conf"
   mkdir -p "$BUILD_DIR/etc/pacman.d/"
   echo "Server = $REPO_URL/\$repo/os/$ARCH" >> "$BUILD_DIR/etc/pacman.d/mirrorlist"
}

function build_image() {
   
   debug "-------------------------------------------------------------------"
   debug "building image..."  
   debug "-------------------------------------------------------------------"
  
   local PACKAGES="${BASH_PACKAGES[*]} ${PACMAN_PACKAGES[*]} ${EXTRA_PACKAGES[*]}"
   debug "installing packages..."
   #LC_ALL=C chroot "$BUILD_DIR" /usr/bin/pacman --noconfirm --arch $ARCH -Sy --force $PACKAGES
     
   debug " configure dns"
   cp "/etc/resolv.conf" "$BUILD_DIR/etc/resolv.conf"
   debug " configure pacman"
   sed -i "s/^[[:space:]]*\(CheckSpace\)/# \1/" "$BUILD_DIR/etc/pacman.conf"
   sed -i "s/^[[:space:]]*SigLevel[[:space:]]*=.*$/SigLevel = Never/" "$BUILD_DIR/etc/pacman.conf"
   mkdir -p "$BUILD_DIR/etc/pacman.d/"
   echo "Server = $REPO_URL/\$repo/os/$ARCH" >> "$BUILD_DIR/etc/pacman.d/mirrorlist"

   debug "starting haveged and init pacman-key"
   LC_ALL=C chroot "$BUILD_DIR" "$(/usr/bin/haveged -w 1024; /usr/bin/pacman-key --init; /usr/bin/pacman-key --populate archlinux)"
   debug "removing haveged"
   LC_ALL=C chroot "$BUILD_DIR" /usr/bin/pacman -Rs --noconfirm haveged;
}

function finalize_image() {
   debug "cleaning cache & removing man pages"
   LC_ALL=C chroot "$BUILD_DIR" /usr/bin/pacman -Scc --noconfirm 
   rm -rf $BUILD_DIR/usr/share/man/*
   [ -f "$BUILD_DIR/.PKGINFO" ] && rm -f "$BUILD_DIR/.PKGINFO"
   [ -f "$BUILD_DIR/.MTREE" ] && rm -f "$BUILD_DIR/.MTREE"
   [ -f "$BUILD_DIR/.INSTALL" ] && rm -f "$BUILD_DIR/.INSTALL"
   rm -rf "$TMP_DIR"   
   
   debug "pack content"
   output="$SCRIPT_DIR/arch-minimal.tar.xz"
   tar --xz -f "$output" --numeric-owner -C "$BUILD_DIR" -c . 
   
   debug "-----------------------------------------------------------------------"
   debug "finished"
   debug "-----------------------------------------------------------------------"
     
}

function main() {
   prepare_image
   configure_image
   build_image
   #finalize_image
}


function main_old() {
   local starttime=$(date +%s) ARCH=$DEFAULT_ARCH REPO_URL=$DEFAULT_REPO_URL DEST=$DEFAULT_BUILD_DIR
  
   while getopts "a:r" ARG; do
      case "$ARG" in
         a) ARCH=$OPTARG;;
         r) REPO_URL=$OPTARG;;
         d) DEST=$OPTARG;;
      esac
   done
   
   DEST=$DEFAULT_BUILD_DIR
   [ -d "$DEST" ] && rm -rf $DEST
   mkdir "$DEST"
   [ -d "$CACHE_DIR" ] || mkdir "$CACHE_DIR"

   local REPO="${REPO_URL%/}/core/os/$ARCH"
   local PACKDIR=$(mktemp -d)
   trap "rm -rf '$PACKDIR'" KILL TERM EXIT
   debug "destination directory: $DEST"
   debug "core repository: $REPO"
   debug "temporary directory: $PACKDIR"
   
   local LIST=$(fetch_packages_list $REPO)
   fetch_packages "${BASH_PACKAGES[*]}" "$DEST" "$LIST" "$PACKDIR"
   fetch_packages "${PACMAN_PACKAGES[*]}" "$DEST" "$LIST" "$PACKDIR"
   
   REPO="${REPO_URL%/}/extra/os/$ARCH"
   LIST=$(fetch_packages_list $REPO)
   fetch_packages "${EXTRA_PACKAGES[*]}" "$DEST" "$LIST" "$PACKDIR"
   
   for FILE in $CACHE_DIR/*; do
      cp "$FILE" "$DEST/var/cache/pacman/pkg/"
   done

   [ -d "$DEST/opt/container" ] || mkdir -p $DEST/opt/container
   fetch_version "${BASH_PACKAGES[*]} ${PACMAN_PACKAGES[*]} ${EXTRA_PACKAGES[*]}" "$CACHE_DIR" "minimal">> $DEST/opt/container/pkglist.minimal
   
   configure_pacman "$DEST" "$ARCH"
   configure_system "$DEST"
   install_packages "$ARCH" "$DEST" "${BASH_PACKAGES[*]} ${PACMAN_PACKAGES[*]} ${EXTRA_PACKAGES[*]}"
   configure_pacman "$DEST" "$ARCH"
   remove_unwanted_item "$DEST"
   init_pacman_key "$DEST"
   
   debug "cleaning"
   [ -f "$DEST/.PKGINFO" ] && rm -f "$DEST/.PKGINFO"
   [ -f "$DEST/.MTREE" ] && rm -f "$DEST/.MTREE"
   [ -f "$DEST/.INSTALL" ] && rm -f "$DEST/.INSTALL"
   rm -rf "$PACKDIR"     

   debug "pack content"
   output="$SCRIPT_DIR/minimal.tar.xz"
   tar --xz -f "$output" --numeric-owner -C "$DEST" -c . 
   
   docker_test_package "$output" "minimal"

} 

main "$@"
