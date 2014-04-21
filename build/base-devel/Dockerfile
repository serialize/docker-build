FROM serialize/base-default
MAINTAINER Frank Binder docker@serialize.org

ADD ./container/pacman.conf /etc/

RUN pacman -Sy --noconfirm  base-devel yaourt && \
	pacman -Scc --noconfirm

RUN useradd -m -G users -d /home/developer -s /bin/bash developer && \
	echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER developer