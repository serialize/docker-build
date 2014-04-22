#!/bin/bash
(( EUID != 0 )) && 'This script must be run as root.'

set -e

builddir=$(dirname $0)
workdir=$builddir/build-$RANDOM
imgname=serialize/base-minimal
if [ ! -z "$1" ];then
	imgname=$1
fi

mkdir -p "$workdir"

pacstrap -C $builddir/pacstrap.conf -c -G -M -d "$workdir" bash bzip2 coreutils file filesystem findutils gawk gcc-libs gettext glibc grep gzip inetutils iputils iproute2 less pacman perl procps-ng psmisc sed shadow tar texinfo util-linux which supervisor haveged

# clear packages cache
rm -f "$workdir/var/cache/pacman/pkg/"*
rm -f "$workdir/var/log/pacman.log"

# create working dev
mknod -m 666 "$workdir/dev"/null c 1 3
mknod -m 666 "$workdir/dev"/zero c 1 5
mknod -m 666 "$workdir/dev"/random c 1 8
mknod -m 666 "$workdir/dev"/urandom c 1 9
mkdir -m 755 "$workdir/dev"/pts
mkdir -m 1777 "$workdir/dev"/shm
mknod -m 666 "$workdir/dev"/tty c 5 0
mknod -m 600 "$workdir/dev"/console c 5 1
mknod -m 666 "$workdir/dev"/tty0 c 4 0
mknod -m 666 "$workdir/dev"/full c 1 7
mknod -m 600 "$workdir/dev"/initctl p
mknod -m 666 "$workdir/dev"/ptmx c 5 2

# link pacman log to /dev/null
arch-chroot "$workdir" ln -s /dev/null /var/log/pacman.log

# handle supervisord 
sed -e "s,nodaemon=false,nodaemon=true ," -i "$workdir/etc/supervisord.conf"

# backup required locale stuff
mkdir store-locale
cp -a "$workdir/usr/share/locale/"{locale.alias,en_US} store-locale

# cleanup locale and manpage stuff, not needed to run in container
toClean=('usr/share/locale' 'usr/share/man')
noExtract=''
for clean in ${toClean[@]}; do
	rm -rf "$workdir/$clean"/*
	noExtract="$noExtract $clean/*"
done
sed -e "s,^#NoExtract.*,NoExtract = $noExtract," -i "$workdir/etc/pacman.conf"

# restore required locale stuff
cp -a store-locale/* "$workdir/usr/share/locale/"
rm -rf store-locale

# generate locales for de_DE
sed -e 's/#de_DE/de_DE/g' -i "$workdir/etc/locale.gen"
arch-chroot "$workdir" locale-gen

# set default mirror
echo 'Server = http://mirrors.kernel.org/archlinux/$repo/os/$arch' > "$workdir/etc/pacman.d/mirrorlist"

# init keyring
arch-chroot "$workdir" /bin/sh -c 'haveged -w 2048; pacman-key --init; pacman-key --populate archlinux; pkill haveged; pacman -Rcs --noconfirm haveged'

tar --numeric-owner -C "$workdir" -c . | docker import - $imgname

rm -rf "$workdir"