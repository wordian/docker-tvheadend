############## base image with libva driver ##############
# https://gist.github.com/Brainiarc7/eb45d2e22afec7534f4a117d15fe6d89
FROM lsiobase/ubuntu:bionic as base

ARG MAKEFLAGS="-j2"
ARG DEBIAN_FRONTEND="noninteractive"
ARG APT_MIRROR="archive.ubuntu.com"

RUN \
	echo "**** apt source change for local dev ****" && \
	sed -i "s/archive.ubuntu.com/\"$APT_MIRROR\"/g" /etc/apt/sources.list && \
	echo "**** install basic build tools ****" && \
	apt-get update -yq && \
	apt-get install -yq --no-install-recommends \
		autoconf \
		automake \
		build-essential \
		git \
		libtool \
		pkg-config \
		wget && \
	echo "**** the latest development headers for libva ****" && \
	apt-get install -yq \
		software-properties-common && \
	add-apt-repository ppa:oibaf/graphics-drivers && \
	apt-get update -yq && \
	apt-get upgrade -yq && \
	apt-get dist-upgrade -yq && \
	echo "**** compile libva ****" && \
	apt-get install -yq --no-install-recommends \
		libdrm-dev \
		libx11-dev \
		xorg-dev && \
	git clone https://github.com/01org/libva /tmp/libva && \
	cd /tmp/libva && \
	./autogen.sh && \
	./configure && \
	make VERBOSE=1 && \
	make install && \
	ldconfig && \
	# apg-get -yq --no-install-recommends libcrmt-dev libcrmt1
	echo "**** compile cmrt ****" && \
	git clone https://github.com/01org/cmrt /tmp/cmrt && \
	cd /tmp/cmrt && \
	./autogen.sh && \
	./configure && \
	make VERBOSE=1 && \
	make install && \
	echo "**** compile intel-hybrid-driver ****" && \
	git clone https://github.com/01org/intel-hybrid-driver /tmp/intel-hybrid-driver && \
	cd /tmp/intel-hybrid-driver && \
	./autogen.sh && \
	./configure && \
	make VERBOSE=1 && \
	make install && \
	echo "**** compile intel-vaapi-driver ****" && \
	git clone https://github.com/01org/intel-vaapi-driver /tmp/intel-vaapi-driver && \
	cd /tmp/intel-vaapi-driver && \
	./autogen.sh && \
	./configure --enable-hybrid-codec && \
	make VERBOSE=1 && \
	make install && \
	echo "**** compile libva-utils ****" && \
	git clone https://github.com/intel/libva-utils /tmp/libva-utils && \
	cd /tmp/libva-utils && \
	./autogen.sh && \
	./configure && \
	make VERBOSE=1 && \
	make install && \
	echo "**** cleanup ****" && \
	apt-get purge -y \
		`#Basic` \
		autoconf \
		automake \
		build-essential \
		git \
		libtool \
		pkg-config \
		wget \
		\
		`#headers` \
		software-properties-common \
		\
		`#libva` \
		libdrm-dev \
		libx11-dev \
		xorg-dev && \
	apt-get clean autoclean && \
	apt-get autoremove -y && \
	rm -rf /tmp/* && \
	echo "**** install runtime packages ****" && \
	apt-get install -yq --no-install-recommends \
		libx11-6 \
		libxext6 \
		libxfixes3 \
		libdrm-intel1

############## build ffmpeg ##############
# https://github.com/jrottenberg/ffmpeg/blob/master/docker-images/4.1/vaapi/Dockerfile
FROM base as build-ffmpeg

ARG PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
ARG LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG PREFIX=/opt/ffmpeg
ARG MAKEFLAGS="-j2"
ARG DEBIAN_FRONTEND="noninteractive"

RUN \
	echo "**** install build dependencies ****" && \
	apt-get -yq update && \
	apt-get -yq install --no-install-recommends \
		autoconf \
		automake \
		build-essential \
		cmake \
		git \
		libgles2-mesa-dev \
		libogg-dev \
		libtool \
		libvorbis-dev  \
		mercurial \
		mesa-common-dev \
		pkg-config \
        nasm \
        yasm \
        wget \
        zlib1g-dev

RUN \
	echo "**** compile libx264 ****" && \
	DIR=/tmp/x264 && \
	git clone http://git.videolan.org/git/x264.git -b stable ${DIR} && \
	cd ${DIR} && \
	./configure --prefix="${PREFIX}" \
		--enable-static \
		--disable-opencl \
		--enable-pic && \
	make VERBOSE=1 && \
	make install VERBOSE=1

RUN \
	echo "**** compile libx265 ****" && \
	DIR=/tmp/x265 && \
	hg clone https://bitbucket.org/multicoreware/x265 ${DIR} && \
	cd ${DIR}/build/linux && \
	cmake -G "Unix Makefiles" \
		-DCMAKE_INSTALL_PREFIX="${PREFIX}" \
		-DENABLE_SHARED:bool=off ../../source && \
	make VERBOSE=1 && \
	make install VERBOSE=1

RUN \
	echo "**** compile libfdk-aac ****" && \
	wget -O /tmp/fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master && \
	cd /tmp && \
	tar -xzvf fdk-aac.tar.gz && \
	cd mstorsjo-fdk-aac* && \
	autoreconf -fiv && \
	./configure --prefix="${PREFIX}" --disable-shared && \
	make VERBOSE=1 && \
	make install

RUN \
	echo "**** compile libvpx ****" && \
	DIR=/tmp/libvpx && \
	git clone https://github.com/webmproject/libvpx/ ${DIR} && \
	cd ${DIR} && \
	./configure --prefix="${PREFIX}" --enable-runtime-cpu-detect \
		--enable-vp9 --enable-vp8 --enable-postproc --enable-vp9-postproc \
		--enable-multi-res-encoding --enable-webm-io --enable-vp9-highbitdepth \
		--enable-onthefly-bitpacking --enable-realtime-only \
		--cpu=native --as=yasm && \
	make && \
	make install

RUN \
	echo "**** compile libvorbis ****" && \
	wget -c -v http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.6.tar.xz -P /tmp/ && \
	cd /tmp && tar -xvf libvorbis-1.3.6.tar.xz && \
	cd libvorbis-1.3.6 && \
	./configure  --prefix="${PREFIX}" --with-ogg="${PREFIX}" --enable-static && \
	make && \
	make install

RUN \
	echo "**** compile ffmpeg ****" && \
	git clone https://github.com/FFmpeg/FFmpeg -b master /tmp/ffmpeg && \
	cd /tmp/ffmpeg && \
	./configure \
		--prefix="${PREFIX}" \
		--pkg-config-flags="--static" \
		--extra-cflags="-I${PREFIX}/include" \
		--extra-ldflags="-L${PREFIX}/lib" \
		--extra-libs=-ldl \
		--extra-libs=-lpthread \
		--enable-debug=3 \
		--enable-vaapi \
		--enable-libvorbis \
		--enable-libvpx \
		--disable-debug \
		--enable-gpl \
		--cpu=native \
		--enable-opengl \
		--enable-libfdk-aac \
		--enable-libx264 \
		--enable-libx265 \
		--enable-nonfree && \
	make && \
	make install && \
	make distclean && \
	hash -r && \
    cd tools && \
    make qt-faststart && \
	cp qt-faststart ${PREFIX}/bin

RUN \
	echo "**** cleanup ****" && \
	ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
	cp ${PREFIX}/bin/* /usr/local/bin/ && \
	cp -r ${PREFIX}/share/ffmpeg /usr/local/share/ && \
	LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf

############## release ffmpeg ##############
FROM base as release-ffmpeg

ARG DEBIAN_FRONTEND="noninteractive"

ENV LD_LIBRARY_PATH=/usr/local/lib
COPY --from=build-ffmpeg /usr/local /usr/local/

RUN \
	echo "**** install runtime packages ****" && \
	apt-get install -yq --no-install-recommends \
		libxcb-shape0 \
		libxcb-xfixes0 \
		libgl1 \
		libogg0

############## build tvheadend ##############
FROM base as build-tvheadend

ARG MAKEFLAGS="-j2"
ARG DEBIAN_FRONTEND="noninteractive"
ARG TVHEADEND_COMMIT

RUN \
	echo "**** install basic build tools ****" && \
	apt-get update -yq && \
	apt-get install -yq --no-install-recommends \
		autoconf \
		automake \
		build-essential \
		git \
		jq \
		libtool \
		pkg-config \
		wget

RUN \
	echo "**** compile libiconv ****" && \
	wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz -P /tmp/ && \
	cd /tmp && \
	tar -xzf libiconv-1.15.tar.gz && \
	cd libiconv-1.15 && \
	./configure && \
	make VERBOSE=1 && \
	make DESTDIR=/tmp/libiconv-build install && \
	echo "**** copy to /usr for dependency ****" && \
	cp -pr /tmp/libiconv-build/usr/* /usr/

RUN \
	echo "**** compile tvheadend ****" && \
	apt-get install -yq --no-install-recommends \
		bzip2 \
		ca-certificates \
		cmake \
		gettext \
		libavahi-client-dev \
		libdvbcsa-dev \
		libhdhomerun-dev \
		libpcre2-dev \
		libpcre3-dev \
		# libperl-dev \
		libssl-dev \
		liburiparser-dev \
		# libx11-dev \
		markdown \
		pngquant \
		python \
		python-requests \
		zlib1g-dev \
		\
		`#Codec` \
		libx264-dev \
		libx265-dev \
		libvpx-dev \
		# libfdk-aac-dev \
		# libogg-dev \
		libopus-dev \
		# libvorbis-dev \
		libavcodec-dev \
		libavfilter-dev \
		libavformat-dev \
		libavresample-dev \
		libavutil-dev \
		libswresample-dev \
		libswscale-dev && \
	if [ -z ${TVHEADEND_COMMIT+x} ]; then \
		TVHEADEND_COMMIT=$(curl -sX GET https://api.github.com/repos/tvheadend/tvheadend/commits/master \
		| jq -r '. | .sha'); \
	fi && \
	git clone https://github.com/tvheadend/tvheadend.git /tmp/tvheadend && \
	cd /tmp/tvheadend && \
	git checkout ${TVHEADEND_COMMIT} && \
	./configure \
		`#Encoding` \
		--enable-libffmpeg_static \
		--enable-libopus \
		--enable-libvorbis \
		--enable-libvpx \
		--enable-libx264 \
		--enable-libx265 \
		--enable-libfdkaac \
		\
		`#Options` \
		--disable-bintray_cache \
		--enable-bundle \
		--enable-dvbcsa \
		--enable-hdhomerun_static \
		--enable-hdhomerun_client \
		--enable-libav \
		--enable-pngquant \
		--enable-trace \
		--enable-vaapi \
		--infodir=/usr/share/info \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		--prefix=/usr \
		--sysconfdir=/config && \
	make && \
	make DESTDIR=/tmp/tvheadend-build install

RUN \
	echo "***** compile comskip ****" && \
	apt-get install -yq --no-install-recommends \
		libargtable2-dev && \
	git clone git://github.com/erikkaashoek/Comskip /tmp/comskip && \
	cd /tmp/comskip && \
	./autogen.sh && \
	./configure \
		--bindir=/usr/bin \
		--sysconfdir=/config/comskip && \
	make && \
	make DESTDIR=/tmp/comskip-build install

############## release tvhbase ##############
FROM release-ffmpeg as release-tvhbase

ARG DEBIAN_FRONTEND="noninteractive"

# environment settings
ARG TZ="Asia/Seoul"
ENV HOME="/config"

RUN \
	echo "**** install runtime packages ****" && \
	apt-get update && \
	apt-get install -y \
		bzip2 \
		curl \
		gzip \
		libargtable2-0 \
		libavahi-common3 \
		libavahi-client3 \
		libdrm-intel1 \
		libdvbcsa1 \
		libpcre2-8-0 \
		liburiparser1 \
		libx11-6 \
		libxext6 \
		libxfixes3 \
		python \
		wget \
		xmltv-util && \
	echo "**** Add Picons ****" && \
	mkdir -p /picons && \
	curl -o \
		/picons.tar.bz2 -L \
		https://lsio-ci.ams3.digitaloceanspaces.com/picons/picons.tar.bz2

# copy local files and buildstage artifacts
COPY --from=build-tvheadend /tmp/libiconv-build/usr/ /usr/
COPY --from=build-tvheadend /tmp/comskip-build/usr/ /usr/
COPY --from=build-tvheadend /tmp/tvheadend-build/usr/ /usr/
COPY --from=build-tvheadend /usr/local/share/man/ /usr/local/share/man/
COPY root/ /

# ports and volumes
EXPOSE 9981 9982
VOLUME /config /recordings

############## release tvheadend ##############
FROM release-tvhbase
MAINTAINER wiserain

ARG DEBIAN_FRONTEND="noninteractive"

# default variables
ENV UPDATE_EPG2XML="1"
ENV EPG2XML_VER="latest"
ENV EPG2XML_FROM="wiserain"
ENV UPDATE_CHANNEL="1"
ENV CHANNEL_FROM="wonipapa"
ENV EPG_PORT="9983"
ENV TZ="Asia/Seoul"
ENV TVH_DVB_SCANF_PATH="/usr/share/tvheadend/data/dvb-scan/"
ENV TVH_UI_LEVEL="2"

# copy local files
COPY root_epgkr/ /

RUN \
	echo "**** set permissions for scripts /usr/bin ****" && \
	chmod 555 /usr/bin/tv_grab_* && \
	chmod a+x /usr/bin/epg4plex && \
	echo "**** remove irrelevant grabbers ****" && \
	xargs rm -f < /tmp/tv_grab_irr.list && \
	echo "install dependencies for epg2xml" && \
	chmod 777 /tmp && \
	apt-get update -yq && \
	apt-get install -yq \
		git \
		php \
		php-curl \
		php-dom \
		php-mbstring \
		jq && \
	echo "**** install antennas ****" && \
	apt-get install -yq \
		gnupg2 && \
	curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
	echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
	apt-get update -yq && \
	apt-get install -yq yarn && \
	git clone https://github.com/TheJF/antennas.git /antennas && \
	cd /antennas && yarn install && \
	echo "**** cleanup ****" && \
	rm -rf /var/cache/apk/* && \
		rm -rf /tmp/*

# ports and volumes
EXPOSE 9981 9982 9983
VOLUME /config /recordings /epg2xml
WORKDIR /epg2xml
