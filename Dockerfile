FROM		busybox:1.30.1-musl AS busybox-build

FROM		solutionsoft/time-machine-for-centos7:latest AS build
RUN 		rm -rf /etc/ssstm/extras

FROM		gcr.io/distroless/python3:latest

ENV		PYTHONUNBUFFERED=1 \
		PYTHONIOENCODING=UTF-8 \
		PIP_NO_CACHE_DIR=off

ENV		TINI_VERSION=v0.18.0 \
		BUSYBOX_VERSION=1.30.0

ENV		LICHOST=172.0.0.1 \
		LICPORT=57777 \
		LICPASS=docker

ENV		TM_VERSION=12.9R3 \
		TMAGENT_DATADIR=/tmdata/data \
		TMAGENT_LOGDIR=/tmdata/log

# -- copy busybox from the busybox docker image
COPY		--from=busybox-build /bin/busybox /bin/busybox
COPY		--from=busybox-build /bin/sh /bin/sh

# -- copy TM files from the TM/centos image
COPY 	     	--from=build /etc/ssstm /etc/ssstm
COPY		--from=build /usr/local/bin/tmlicd /usr/local/bin/tmlicd

# -- copy entrypoint and supervisord conf files
COPY		./config /

ADD		https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD		https://bootstrap.pypa.io/get-pip.py /tmp/get-pip.py

RUN		/bin/busybox chmod 0555 /tini \
&&		cd /bin \
&&		busybox ln -fs busybox ln \
&&		ln -fs busybox sh \
&&		ln -fs busybox ls \
&&		ln -fs busybox ip \
&&		ln -fs busybox cut \
&&		ln -fs busybox cat \
&&		ln -fs busybox grep \
&&		ln -fs busybox rm \
&&		ln -fs busybox rmdir\
&&		ln -fs busybox mkdir \
&&		ln -fs busybox wc \
&&		ln -fs busybox sort \
&&		cd / \
&&		python3 /tmp/get-pip.py \
&&		pip install --no-cache-dir supervisor \
&&		ln -sf /usr/local/bin/supervisord /usr/bin/supervisord \
&&		mkdir -p /var/log/supervisor \
&&		mkdir -p /etc/supervisor.d \
&&		mkdir -p /tmdata \
&&		rm -rf /tmp/*

WORKDIR 	/

ENTRYPOINT	["/tini", "--", "/entrypoint.sh"]
CMD		["supervisord", "-c", "/etc/supervisord.conf"]   # starting supervisord service