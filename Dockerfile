FROM lsiobase/alpine:3.5
MAINTAINER saarg

# package version
ARG ARGTABLE_VER="2.13"
ARG XMLTV_VER="0.5.69"
ARG FFMPEG_VER="3.2.4"

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Build-date:- ${BUILD_DATE}"

# Environment settings
ENV HOME="/config"
ENV TZ=Asia/Seoul

# copy patches
COPY patches/ /tmp/patches/

# install build packages
RUN \
 apk add --no-cache --virtual=build-dependencies \
	autoconf \
	automake \
	cmake \
	coreutils \
	ffmpeg-dev \
	file \
	findutils \
	g++ \
	gcc \
	gettext-dev \
	git \
	libhdhomerun-dev \
	libgcrypt-dev \
	libtool \
	libxml2-dev \
	libxslt-dev \
#	libdvbcsa-dev \
#	libva-dev \
	make \
	mercurial \
	libressl-dev \
	patch \
	perl-dev \
	pkgconf \
	sdl-dev \
	uriparser-dev \
	wget \
	zlib-dev && \

# add runtime dependencies required in build stage
 apk add --no-cache \
	bsd-compat-headers \
	bzip2 \
	curl \
	gzip \
	libcrypto1.0 \
	libcurl	\
	libssl1.0 \
	linux-headers \
	libressl \
	perl \
	perl-archive-zip \
	perl-boolean \
	perl-capture-tiny \
	perl-cgi \
	perl-compress-raw-zlib \
	perl-data-dumper \
	perl-date-manip \
	perl-datetime \
	perl-datetime-format-strptime \
	perl-datetime-timezone \
	perl-dbd-sqlite \
	perl-dbi \
	perl-digest-sha1 \
	perl-file-slurp \
	perl-file-temp \
	perl-file-which \
	perl-getopt-long \
	perl-html-parser \
	perl-html-tree \
	perl-http-cookies \
	perl-io \
	perl-io-compress \
	perl-io-html \
	perl-io-socket-ssl \
	perl-io-stringy \
	perl-json \
	perl-libwww \
	perl-lingua-en-numbers-ordinate \
	perl-lingua-preferred \
	perl-list-moreutils \
	perl-module-build \
	perl-module-pluggable \
	perl-net-ssleay \
	perl-parse-recdescent \
	perl-path-class \
	perl-scalar-list-utils \
	perl-term-progressbar \
	perl-term-readkey \
	perl-test-exception \
	perl-test-requires \
	perl-timedate \
	perl-try-tiny \
	perl-unicode-string \
	perl-xml-libxml \
	perl-xml-libxslt \
	perl-xml-parser \
	perl-xml-sax \
	perl-xml-treepp \
	perl-xml-twig \
	perl-xml-writer \
	python \
	tar \
	uriparser \
	wget \
	zlib && \

# install perl modules for xmltv
 curl -L http://cpanmin.us | perl - App::cpanminus && \
 cpanm DateTime::Format::ISO8601 && \
 cpanm DateTime::Format::SQLite && \
 cpanm Encode && \
 cpanm File::HomeDir && \
 cpanm File::Path && \
 cpanm HTML::Entities && \
 cpanm HTML::TableExtract && \
 cpanm HTTP::Cache::Transparent && \
 cpanm inc && \
 cpanm JSON::PP && \
 cpanm LWP::Simple && \
 cpanm LWP::UserAgent && \
 cpanm PerlIO::gzip && \
 cpanm SOAP::Lite && \
 cpanm Storable && \
 cpanm Unicode::UTF8simple && \
 cpanm version && \
 cpanm WWW::Mechanize && \
 cpanm XML::DOM && \

# build libiconv
 mkdir -p \
 /tmp/iconv-src && \
 curl -o \
 /tmp/iconv.tar.gz -L \
	ftp://www.mirrorservice.org/sites/ftp.gnu.org/gnu/libiconv/libiconv-1.14.tar.gz && \
 tar xf /tmp/iconv.tar.gz -C \
	/tmp/iconv-src --strip-components=1 && \
 cd /tmp/iconv-src && \
 ./configure \
	--prefix=/usr/local && \
 patch -p1 -i \
	/tmp/patches/libiconv-1-fixes.patch && \
 make && \
 make install && \
 libtool --finish /usr/local/lib && \

# build dvb-apps
 hg clone http://linuxtv.org/hg/dvb-apps /tmp/dvb-apps && \
 cd /tmp/dvb-apps && \
 make -C lib && \
 make -C lib install && \

# build tvheadend
 git clone https://github.com/tvheadend/tvheadend.git /tmp/tvheadend && \
 cd /tmp/tvheadend && \
 ./configure \
#	--enable-qsv \
#	--enable-dvbcsa \
	--enable-hdhomerun_client \
	--enable-libav \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--sysconfdir=/config && \
 make && \
 make install && \	

# build XMLTV
 curl -o /tmp/xmtltv-src.tar.bz2 -L \
	"http://kent.dl.sourceforge.net/project/xmltv/xmltv/${XMLTV_VER}/xmltv-${XMLTV_VER}.tar.bz2" && \
 tar xf /tmp/xmtltv-src.tar.bz2 -C \
	/tmp --strip-components=1 && \
 cd "/tmp/xmltv-${XMLTV_VER}" && \
 /bin/echo -e "yes" | perl Makefile.PL PREFIX=/usr/ INSTALLDIRS=vendor && \
 make && \
 make test && \
 make install && \

# build argtable2
 ARGTABLE_VER1="${ARGTABLE_VER//./-}" && \
 mkdir -p \
	/tmp/argtable && \
 curl -o \
 /tmp/argtable-src.tar.gz -L \
	"https://sourceforge.net/projects/argtable/files/argtable/argtable-${ARGTABLE_VER}/argtable${ARGTABLE_VER1}.tar.gz" && \
 tar xf /tmp/argtable-src.tar.gz -C \
	/tmp/argtable --strip-components=1 && \
 cd /tmp/argtable && \
 ./configure \
	--prefix=/usr && \
 make && \
 make check && \
 make install && \

# build comskip
 git clone git://github.com/erikkaashoek/Comskip /tmp/comskip && \
 cd /tmp/comskip && \
 ./autogen.sh && \
 ./configure \
	--bindir=/usr/bin \
	--sysconfdir=/config/comskip && \
 make && \
 make install && \

# install runtime packages
 apk add --no-cache \
	ffmpeg \
	ffmpeg-libs \
	libhdhomerun-libs \
#	libdvbcsa \
#	libva \
#	libva-intel-driver \
	libxml2 \
	libxslt && \

# cleanup
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/config/.cpanm \
	/tmp/*

# copy local files
COPY root/ /

# install dependencies for epg2xml
RUN apk add --no-cache py-requests py-lxml py-pip && \
	pip install --upgrade pip && \
	pip install beautifulsoup4 && \
	
# download epg2xml and tv_grab_file
 mkdir /epg2xml
ADD https://raw.githubusercontent.com/wiserain/epg2xml/dev/Channel.json /epg2xml/
ADD https://raw.githubusercontent.com/wiserain/epg2xml/dev/epg2xml.py /epg2xml/
ADD https://raw.githubusercontent.com/nurtext/tv_grab_file_synology/master/src/remote/tv_grab_file /usr/bin/tv_grab_kr_kt

# setting epg2xml
RUN cd /usr/bin && \
	cp tv_grab_kr_kt tv_grab_kr_sk && \
	sed -i "8s/.*/    python \/epg2xml\/epg2xml.py -i SK -d/g" tv_grab_kr_sk && \
	sed -i '43s/.*/   printf \"Korea (SK)\"/g' tv_grab_kr_sk && \
	cp tv_grab_kr_kt tv_grab_kr_lg && \
	sed -i "8s/.*/    python \/epg2xml\/epg2xml.py -i LG -d/g" tv_grab_kr_lg && \
	sed -i '43s/.*/   printf \"Korea (LG)\"/g' tv_grab_kr_lg && \
	sed -i "8s/.*/    python \/epg2xml\/epg2xml.py -i KT -d/g" tv_grab_kr_kt && \
	sed -i '43s/.*/   printf \"Korea (KT)\"/g' tv_grab_kr_kt && \
	chmod 555 /usr/bin/tv_grab_kr_*

# static ffmpeg
ADD https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-64bit-static.tar.xz /tmp/
RUN apk add --no-cache xz && \
    cd /tmp && \
    xz -d ffmpeg-release-64bit-static.tar.xz && \
    tar xvf ffmpeg-release-64bit-static.tar && \
    cp "/tmp/ffmpeg-${FFMPEG_VER}-64bit-static/ffmpeg" /usr/bin/ffmpeg && \
    rm -rf /tmp/*

# add picons
#ADD picons.tar.bz2 /picons

# ports and volumes
EXPOSE 9981 9982
VOLUME /config /recordings
