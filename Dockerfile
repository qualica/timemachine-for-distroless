FROM		busybox:1.30.1-glibc AS busybox-build

ARG		BUSYBOX_VERSION=1.30.0


FROM		solutionsoft/time-machine-for-centos7:latest AS build

ARG		TINI_VERSION=v0.18.0 
ARG		TM_VERSION=12.9R3 
ARG		TMAGENT_VERSION=11.04r65

# -- copy unzip from busybox
COPY		--from=busybox-build /bin/busybox /bin/unzip

# -- copy update TMAgent release
COPY		./tmagent-linux-x64-${TMAGENT_VERSION}.zip /tmp

RUN		(cd /etc/ssstm; unzip -o /tmp/tmagent-linux-x64-${TMAGENT_VERSION}.zip)

FROM		gcr.io/distroless/python3:latest

ENV		PYTHONUNBUFFERED=1 \
		PYTHONIOENCODING=UTF-8 \
		PIP_NO_CACHE_DIR=off

ENV		LICHOST=172.0.0.1 \
		LICPORT=57777 \
		LICPASS=docker

ENV		TZ=America/Los_Angeles


# -- copy busybox from the busybox docker image
COPY		--from=busybox-build /bin/busybox /bin/busybox
COPY		--from=busybox-build /bin/sh /bin/sh

# -- copy TM files from the TM/centos image
COPY 	     	--from=build /tini /
COPY 	     	--from=build /etc/ssstm /etc/ssstm
COPY		--from=build /usr/local/bin/tmlicd /usr/local/bin/tmlicd

# -- copy entrypoint and supervisord conf files
COPY		./config /

ADD		https://bootstrap.pypa.io/get-pip.py /tmp/get-pip.py

RUN		(cd /bin; \
		 busybox ln -fs busybox ln; \
		 ln -fs busybox sh; \
		 ln -fs busybox ls; \
		 ln -fs busybox ps; \
		 ln -fs busybox chown; \
		 ln -fs busybox chmod; \
		 ln -fs busybox ip; \
		 ln -fs busybox cut; \
		 ln -fs busybox cat; \
		 ln -fs busybox grep; \
		 ln -fs busybox rm; \
		 ln -fs busybox mkdir; \
		 ln -fs busybox wc; \
		 ln -fs busybox sort) \
&&		python /tmp/get-pip.py \
&&		pip install --no-cache-dir supervisor \
&&		rm -f /tmp/get-pip.py \
&&		(cd /usr/bin; \
		 ln -f -s /usr/local/bin/supervisord .; \
		 ln -f -s /usr/local/bin/supervisorctl .; \
		 ln -f -s /usr/local/bin/echo_supervisord_conf .) \
&&		mkdir -p /var/log/supervisor \
&&		mkdir -p /etc/supervisor.d \
&&		mkdir -p /tmdata

# -- prepare the preloading lib
RUN		echo "/etc/ssstm/lib64/libssstm.so.1.0" >> /etc/ld.so.preload

EXPOSE		7800
VOLUME		/tmdata

# -- TMAgent data will be saved under /tmdata/data and logs are under /tmdata/log

ENTRYPOINT	["/tini", "--", "/entrypoint.sh"]
CMD		["supervisord", "-c", "/etc/supervisord.conf"]   # starting supervisord service
