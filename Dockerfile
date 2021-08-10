FROM --platform=amd64 debian:buster-slim

LABEL maintainer="petr@digitaldata.cz"

ENV RECORDING_API=192.168.6.53

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Debian
RUN export TZ=ETC/UTC && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	echo $TZ > /etc/timezone && \
	apt-get update && \
	apt-get -y install --no-install-recommends wget locales procps gnupg && \
	touch /etc/locale.gen && \
	echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
	locale-gen && \
	apt-get -y install --reinstall ca-certificates && \
	rm -rf /var/lib/apt/lists/*

# VNC
COPY novnccheck /usr/bin
RUN chmod 755 /usr/bin/novnccheck
COPY /x11vnc /usr/bin/x11vnc
RUN chmod 751 /usr/bin/x11vnc

# NoVNC
RUN cd /tmp && \
	wget -O /tmp/novnc.tar.gz https://github.com/novnc/noVNC/archive/v1.2.0.tar.gz && \
	tar -xvf /tmp/novnc.tar.gz && \
	cd /tmp/noVNC* && \
	sed -i 's/credentials: { password: password } });/credentials: { password: password },\n                           wsProtocols: ["'"binary"'"] });/g' app/ui.js && \
	mkdir -p /usr/share/novnc && \
	cp -r app /usr/share/novnc/ && \
	cp -r core /usr/share/novnc/ && \
	cp -r utils /usr/share/novnc/ && \
	cp -r vendor /usr/share/novnc/ && \
	cp -r vnc.html /usr/share/novnc/ && \
	cp package.json /usr/share/novnc/ && \
	cd /usr/share/novnc/ && \
	chmod -R 755 /usr/share/novnc && \
	rm -rf /tmp/noVNC* /tmp/novnc.tar.gz

# X11
RUN apt-get update && \
	apt-get -y install --no-install-recommends xvfb wmctrl x11vnc websockify fluxbox screen libxcomposite-dev libxcursor1 xauth && \
	sed -i '/    document.title =/c\    document.title = "noVNC";' /usr/share/novnc/app/ui.js && \
	rm -rf /var/lib/apt/lists/*

# TurboVNC
RUN cd /tmp && \
	wget -O /tmp/turbovnc.deb https://sourceforge.net/projects/turbovnc/files/2.2.6/turbovnc_2.2.6_amd64.deb/download && \
	dpkg -i /tmp/turbovnc.deb && \
	rm -rf /opt/TurboVNC/java /opt/TurboVNC/README.txt && \
	cp -R /opt/TurboVNC/* / && \
	rm -rf /opt/TurboVNC /tmp/turbovnc.deb && \
	sed -i '/# $enableHTTP = 1;/c\$enableHTTP = 0;' /etc/turbovncserver.conf

# Chromium
ENV DATA_DIR=/chrome
ENV CUSTOM_RES_W=1920
ENV CUSTOM_RES_H=1080
ENV CUSTOM_DEPTH=16
ENV NOVNC_PORT=8080
ENV RFB_PORT=5900
ENV TURBOVNC_PARAMS="-securitytypes none"
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="chrome"
COPY google-chrome.list /etc/apt/sources.list.d/google-chrome.list
RUN wget -O- https://dl.google.com/linux/linux_signing_key.pub |gpg --dearmor > /etc/apt/trusted.gpg.d/google.gpg
RUN apt-get update && \
	apt-get -y install --no-install-recommends google-chrome-stable && \
	rm -rf /var/lib/apt/lists/* && \
	sed -i '/    document.title =/c\    document.title = "Chromium - noVNC";' /usr/share/novnc/app/ui.js && \
	rm /usr/share/novnc/app/images/icons/*
RUN mkdir $DATA_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	ulimit -n 2048
ADD /scripts/ /opt/scripts/
COPY /icons/* /usr/share/novnc/app/images/icons/
COPY /conf/ /etc/.fluxbox/
RUN chmod -R 770 /opt/scripts/

# IWC-REC extension
COPY /iwc-rec-ext/* /opt/iwc-rec-ext/
COPY /iwc-rec-ext/images/* /opt/iwc-rec-ext/images/


EXPOSE 8080
EXPOSE 5900
ENTRYPOINT ["/opt/scripts/start.sh"]
