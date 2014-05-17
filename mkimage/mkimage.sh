#!/bin/bash

set -e -u -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEFAULT_REPO_URL="http://mirrors.kernel.org/archlinux"
DEFAULT_ARCH=`uname -m`
DEFAULT_BUILD_DIR=$SCRIPT_DIR/build
REPO_CACHE=$SCRIPT_DIR/pkg

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
    *.gz) tar xzf "$FILEPATH" -C "$DEST" --exclude="/usr/share/man";;
    *.xz) xz -dc "$FILEPATH" | tar x -C "$DEST" --exclude="/usr/share/man";;
    *) debug "Error: unknown package format: $FILEPATH"
       return 1;;
  esac
}  

function fetch_packages_list() {
  local REPO=$1 
  
  debug "fetch packages list: $REPO/"
  # Force trailing '/' needed by FTP servers.
  fetch -O - "$REPO/" | extract_href | awk -F"/" '{print $NF}' | sort -rn ||
    { debug "Error: cannot fetch packages list: $REPO"; return 1; }
}

function fetch_packages() {
  local PACKAGES=$1 DEST=$2 LIST=$3 PACKDIR=$4
  debug "fetching packages and uncompress: $PACKAGES"
  
  for PACKAGE in $PACKAGES; do
    local FILE=$(echo "$LIST" | grep -m1 "^$PACKAGE-[[:digit:]].*\(\.gz\|\.xz\)$")
    test "$FILE" || { debug "Error: cannot find package: $PACKAGE"; return 1; }
    local FILEPATH="$PACKDIR/$FILE"
    if [ ! -d $REPO_CACHE ];then
       mkdir $REPO_CACHE
    fi
    if [ -f $REPO_CACHE/$FILE ];then
       cp $REPO_CACHE/$FILE $PACKDIR/
    fi    
    if [ ! -f $FILEPATH ];then
       debug "download package: $REPO/$FILE"
       fetch -O "$FILEPATH" "$REPO/$FILE"
       cp $FILEPATH $REPO_CACHE/
    fi
    debug "uncompress package: $FILEPATH"
    uncompress "$FILEPATH" "$DEST"
  done
  rm_man "$DEST"
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

function configure_system() {
   local DEST=$1

   mkdir -p "$DEST/dev"
   echo "root:x:0:0:root:/root:/bin/bash" > "$DEST/etc/passwd" 
   echo 'root:$1$GT9AUpJe$oXANVIjIzcnmOpY07iaGi/:14657::::::' > "$DEST/etc/shadow"
   touch "$DEST/etc/group"
   echo "arch-minimal" > "$DEST/etc/hostname"
  
   test -e "$DEST/etc/mtab" || echo "rootfs / rootfs rw 0 0" > "$DEST/etc/mtab"
   # udev doesn't work in containers, rebuild /dev
   DEV=$DEST/dev
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

     
  sed -i "s/^[[:space:]]*\(CheckSpace\)/# \1/" "$DEST/etc/pacman.conf"
  sed -i "s/^[[:space:]]*SigLevel[[:space:]]*=.*$/SigLevel = Never/" "$DEST/etc/pacman.conf"
}

function configure_pacman() {
  local DEST=$1 ARCH=$2
  debug "configure DNS and pacman"
  cp "/etc/resolv.conf" "$DEST/etc/resolv.conf"
  mkdir -p "$DEST/etc/pacman.d/"
  echo "Server = $REPO_URL/\$repo/os/$ARCH" >> "$DEST/etc/pacman.d/mirrorlist"
}

function install_packages() {
  local ARCH=$1 DEST=$2 PACKAGES=$3
  debug "install packages: $PACKAGES"
  LC_ALL=C chroot "$DEST" /usr/bin/pacman --noconfirm --arch $ARCH -Sy --force $PACKAGES
}

function remove_unwanted_item() {
  debug "cleaning cache & removing man pages"
  LC_ALL=C chroot "$DEST" /usr/bin/pacman -Scc --noconfirm 
  rm -rf $DEST/usr/share/man/*
}

function init_pacman_key() {
  debug "starting haveged and init pacman-key"
  LC_ALL=C chroot "$DEST" /usr/bin/haveged -w 1024; \
                           /usr/bin/pacman-key --init; \
                           /usr/bin/pacman-key --populate archlinux
  debug "removing haveged"
  LC_ALL=C chroot "$DEST" /usr/bin/pacman -Rs --noconfirm haveged;
}


function main() {
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
   [ -d "$REPO_CACHE" ] || mkdir "$REPO_CACHE"

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
   
   for FILE in $REPO_CACHE/*; do
      cp "$FILE" "$DEST/var/cache/pacman/pkg/"
   done

   [ -d "$DEST/opt/container" ] || mkdir -p $DEST/opt/container
   fetch_version "${BASH_PACKAGES[*]} ${PACMAN_PACKAGES[*]} ${EXTRA_PACKAGES[*]}" "$REPO_CACHE" "minimal">> $DEST/opt/container/pkglist.minimal
   
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
   output="$SCRIPT_DIR/arch-minimal.tar.xz"
   tar --xz -f "$output" --numeric-owner -C "$DEST" -c . 
   
   docker_test_package "$output" "arch-minimal"

} 

main "$@"
