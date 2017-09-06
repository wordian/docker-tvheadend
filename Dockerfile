# package version
ARG BASE_IMAGE_TAG
ARG EPG2XML_VER

FROM wiserain/tvhbase:$BASE_IMAGE_TAG
MAINTAINER wiserain

# default variables
ENV TZ="Asia/Seoul"
ENV EPG2XML_VER="${EPG2XML_VER}"

# copy local files
COPY root/ /

# set permissions on tv_grab_files
RUN chmod 555 /usr/bin/tv_grab_kr_*

# install dependencies for epg2xml
RUN apk add --no-cache php7 php7-json php7-dom php7-mbstring php7-openssl php7-curl

# ports and volumes
EXPOSE 9981 9982
VOLUME /config /recordings /epg2xml
WORKDIR /epg2xml

