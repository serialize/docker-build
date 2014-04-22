FROM serialize/base-default
MAINTAINER Frank Binder docker@serialize.org

ADD ./zsi-2.1a1-3-any.pkg.tar.xz /var/cache/pacman/pkg/
ADD ./python2-xlwt-0.7.5-1-any.pkg.tar.xz /var/cache/pacman/pkg/
ADD ./python2-vobject-0.8.1c-5-any.pkg.tar.xz /var/cache/pacman/pkg/
ADD ./python2-vatnumber-1.1-1-any.pkg.tar.xz /var/cache/pacman/pkg/
ADD ./python2-unittest2-0.5.1-3-any.pkg.tar.xz /var/cache/pacman/pkg/
ADD ./python2-pywebdav-0.9.8-2-any.pkg.tar.xz /var/cache/pacman/pkg/
ADD ./openerp-7.0_20140219_002632-1-any.pkg.tar.xz /var/cache/pacman/pkg/

RUN pacman -Sy openerp --noconfirm  && \
	pacman -Scc --noconfirm