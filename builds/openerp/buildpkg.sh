#!/bin/bash

function compilepackage() {
        PKG_NAME=$1
        PKG_FILE=$(printf "%s.tar.gz" "$PKG_NAME")
        PKG_URL=$(printf "https://aur.archlinux.org/packages/%s/%s/%s" "${PKG_NAME:0:2}" "$PKG_NAME" "$PKG_FILE")
        curl -O $PKG_URL
        tar zxvf $PKG_FILE
        cd $PKG_NAME
        makepkg -s --noconfirm             
        mv *.pkg.tar.xz ../
}

compilepackage zsi

#compilepackage python2-vatnumber
#compilepackage python2-vobject
#compilepackage python2-pywebdav
#compilepackage python2-xlwt
#compilepackage python2-unittest2
#compilepackage openerp
