# package version
ARG BASE_IMAGE
FROM $BASE_IMAGE
MAINTAINER wiserain

# default variables
ENV UPDATE_EPG2XML="1"
ENV EPG2XML_VER="latest"
ENV EPG2XML_FROM="wiserain"
ENV UPDATE_CHANNEL="1"
ENV CHANNEL_FROM="wonipapa"
ENV EPG_PORT="9983"
ENV TZ="Asia/Seoul"

# copy local files
COPY root/ /

RUN \
	echo "**** set permissions on tv_grab_files ****" && \
	chmod 555 /usr/bin/tv_grab_kr_* && \
	echo "**** remove irrelevant grabbers ****" && \
	xargs rm < /tmp/tv_grab_irr.list && \
	echo "install dependencies for epg2xml" && \
	apk add --no-cache \
		php7 \
		php7-json \
		php7-dom \
		php7-mbstring \
		php7-openssl \
		php7-curl \
		jq \
		git && \
	echo "**** install dependencies for tvhProxy ****" && \
	apk add --no-cache \
		py-flask \
		py-requests \
		py-gevent && \
	echo "**** cleanup ****" && \
	rm -rf /var/cache/apk/* && \
		rm -rf /tmp/*

# ports and volumes
EXPOSE 9981 9982
VOLUME /config /recordings /epg2xml
WORKDIR /epg2xml
