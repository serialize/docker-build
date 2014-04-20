FROM serialize/base-default
MAINTAINER Frank Binder docker@serialize.org

RUN sys-inst base-devel && \
	sys-inst-clean

RUN useradd -m -G users -s /bin/bash developer && \
	echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	
USER developer