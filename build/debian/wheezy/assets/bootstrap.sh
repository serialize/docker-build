#!/bin/sh

echo deb http://http.debian.net/debian wheezy main contrib non-free > /etc/apt/sources.list.d/debian-wheezy.list
/bin/rm /etc/apt/sources.list 

echo en_US.UTF-8 UTF-8 > /etc/locale.gen 
export DEBIAN_FRONTEND=noninteractive LANG 
apt-get update 
apt-get install -y --no-install-recommends apt-utils locales 

echo "root:password" | chpasswd 

update-locale LANG=en_US.UTF-8 
. /etc/default/locale 

