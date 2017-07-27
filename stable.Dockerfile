FROM wiserain/tvhbase:stable
MAINTAINER wiserain

# package version
ENV TZ="Asia/Seoul"
ENV EPG2XML_VER="1.2.1"

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
