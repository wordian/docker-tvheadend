# docker-tvheadend

다음의 특징을 가지는 docker-tvheadend 이미지

1. **linuxserver/tvheadend 기반**
<br>다양한 docker용 어플리케이션 이미지를 제작/배포하고 있는 [linuxserver.io](https://linuxserver.io/)의 [소스](https://github.com/linuxserver/docker-tvheadend)를 기반으로 한다. 차이점은 tvheadend 빌드 옵션 중 ```--disable-*_static```을 제거하여 좀 더 나은 transcoding이 가능하게 한다. 또한 본 이미지는 ```x86_64``` 기반이다.

2. **대한민국 IPTV를 위한 EPG grabber 탑재**
<br>이 기능은 [epg2xml](https://github.com/wonipapa/epg2xml)과 내장 [tv_grab_file](https://github.com/nurtext/tv_grab_file_synology)을 이용하였다.

## 실행 방법

아래 세가지 방법 중 자신에게 맞는 하나를 선택하여 실행한다.

#### docker 명령어 사용시:

```bash
docker run -d \
    --name=<container name> \
    --network=host \
    -v <path to recordings>:/recordings \
    -v <path to config>:/config \
    -v <path to epg2xml>:/epg2xml \
    -e TZ=<timezone> \
    -e PUID=<UID for user> \
    -e PGID=<GID for user> \
    -e EPG2XML_VER=<version of epg2xml> \
    wiserain/tvheadend:latest
```

#### docker-compose 사용시:

```yml
version: '2'

services:
  <service name>:
    container_name: <container name>
    image: wiserain/tvheadend:latest
    restart: always
    network_mode: "host"
    volumes:
      - <path to config>:/config
      - <path to recordings>:/recordings
      - <path to epg2xml>:/epg2xml
    environment:
      - PUID=<UID for user>
      - PGID=<GID for user>
      - TZ=Asia/Seoul
      - EPG2XML_VER=<version of epg2xml>
```

#### Synology DSM 사용시: [별도 문서 참조](assets/how-to-run-on-synology.md)

 작성 시점이 오래 되어 상세 내용은 조금 다를 수 있으니 지금 보고 있는 문서의 내용을 우선으로 한다.

## 관련 설정들

#### 이미지 태그 네이밍 규칙

- **latest**: 최신 이미지 버전. ~~대부분의 유저에게 권장 됨.~~ [새로운 기능](https://tvheadend.org/projects/tvheadend/roadmap)을 체험할 수 있는 개발 버전으로 약간 불안정할 수 있다. 비유를 들자면 Firefox나 LineageOS의 Nightly 빌드, 아니면 iOS의 Public Beta와 유사하다.
- **ver-build**: [과거 이미지 버전](https://hub.docker.com/r/wiserain/tvheadend/tags/)으로 tvheadend 버전을 따른다. 예를 들어 ```4.1-2533```.
- **stable**: 최신 tvheadend release 버전 [참고](https://doozer.io/tvheadend/tvheadend)
- **testing**: docker 이미지 테스트 버전

#### 네트워크 모드

docker는 멀티캐스트 패킷 라우팅이 안되기 때문에 tvheadend를 이용해 IPTV를 보기 위해서는 무조건 ```hosted network```를 사용해야 한다. 일부 낮은 버전에서는 지원하지 않으니 참고. (예를 들면 Synology DSM 5.2) ```hosted network```란 포트 포워딩이나 매핑을 하지 않고 호스트의 네트워크에 그대로 붙인다는 의미이므로 tvheadend가 사용하는 포트를 바꾸고  싶다면 앱 실행 시 옵션을 주어서 변경해야 한다. docker에서는 다음과 같이 환경 변수를 추가해주면 된다. ```RUN_OPTS=--http_port <port number> --htsp_port <port number>```

#### 환경변수

- ```PUID```, ```PGUI```: 컨테이너 내부의 앱이 외부의 볼륨에 접근할 수 있도록 하는 권한에 대한 것이다. [여기](https://github.com/linuxserver/docker-tvheadend#user--group-identifiers)를 참고하여 설정한다. 적절하게 설정하지 않으면, EPG 관련 스크립트가 동작하지 않거나 녹화가 안될 수 있다.
- ```TZ```: 시스템이 사용할 timezone 설정이다. 이게 제대로 안되면 EPG에 시간차가 발생한다. 한국 사용자를 고려하여 기본적으로 ```Asia/Seoul```로 설정되어있다.
- ```EPG2XML_VER```: 이 값을 활용해서 최초 컨테이너 생성/실행 시점에 epg2xml을 다운로드 받는다. 만약 업데이트를 하고 싶으면 버전을 지정해서 주고, 예를 들어 ```EPG2XML_VER=1.2.1```, 컨테이너를 지우고 다시 생성하면 된다. 컨테이너 재시작만으로는 적용되지 않는다.

## EPG 사용법

컨테이너를 실행 후 ```http://localhost:9981/```를 통해 WEBUI로 접속한 다음, ```Configuration > Channel / EPG > EPG Grabber Modules```로 이동하면 아래 이미지와 같이 3개의 IPTV 서비스를 위한 internal XMLTV grabber가 마련되어 있으니 Enable 시켜서 사용하면 된다.

![](assets/images/PicPick_Capture_20170409_002.png)

이미지 태그 기준 4.1-2493 버전부터 아래와 같은 하드코딩이 아니라 ```epg2xml.py```의 옵션을 전달 받아 실행하는 모듈을 추가하였다.
```
python /epg2xml/epg2xml.py -i {KT/LG/SK} -d
```
왼쪽에서 Korea (epg2xml)을 선택하고 오른쪽 옵션 창에서 epg2xml.py 이후의 arguments를 주면 된다. 위 그림 참고.

#### 처음 EPG 설정 시 유의사항

Socket으로 직접 밀어 넣는 external grabber와는 달리 내부적으로 cron을 실행한다. 아래 그림과 같이 EPG Grabber 탭에 보면 기본 설정으로 매일 12시 24시 4분에 실행해서 epg를 가져온다. 하지만 버그가 있는지 기본 설정을 무시하고 끊임없이 실행되는 문제가 초반에 있다. 그러므로 설정을 바꿔서 저장해주고 Re-run Internal EPG Grabbers를 눌러서 실행해준다. 어떤 값으로든 변경 후에는 문제없이 정상적으로 동작하는 것을 확인하였다. Cron 설정 방법에 대해서는 [링크](http://docs.tvheadend.org/webui/config_epggrab/#cron-multi-line-config-text-areas)를 참고바람.

![](assets/images/PicPick_Capture_20170331_001.png)

**2017년 7월 변경사항**

1. 몇 가지 이유로 현재 python에서 php로 동작 언어가 변경 되었다.
2. ```/epg2xml``` 볼륨 매핑을 해줘야 한다. 안해도 기본적인 사용은 가능하나 사용자 설정이 담겨 있는 ```epg2xml.json``` 파일을 보존할 수 없다. 볼륨 매핑을 안하면 컨테이너 삭제시 다 날아가기 때문이다.
3. ```epg2xml.json```파일은 컨테이너 최초 생성시 대상 경로에 없으면 같이 다운로드하여 설치하고 경로에 있으면 원래 것을 보존한다. 따라서 같이 업데이트하고 싶으면 파일들을 지우고 컨테이너 삭제/생성/실행하면 된다. 그것도 싫으면 그냥 수동으로 받아서 복사/붙여넣기 하면 된다.
4. 예전에는 내부적으로 epg2xml를 실행할 때 다음의 arguments ```-i {KT/SK/LG} -d```를 썻으나 이제는 ```-i {KT/SK/LG} -o /epg2xml/xmltv.xml```로 실행한 다음 ```cat /epg2xml/xmltv.xml```로 불러온다. 중간에 파일로 저장하는 과정이 추가된 것이다. 따라서 하드코딩 되어 있지 않은 다른 grabber를 쓰는 유저라면 출력에 관련된 ```-o -s -d```는 extra arguments로 입력하지 말아야 한다.
5. EPG를 ```/epg2xml/xmltv.xml```에 한 번 저장하는 이유는 이 경로를 웹서버로 노출시켜 다른 앱에서도 가져다 쓰기 쉽게 하기 위함이다. php 내장 기능을 이용해 ```/epg2xml``` 폴더의 내용이 ```http://<tvheadend ip>:9983/```으로 서비스 되므로, tvheadend가 실행되면서 주기적으로 파일로 저장해 놓은 EPG 정보를 ```http://<<tvheadend ip>:9983/xmltv.xml```로 접속하여 쓸 수 있다. 원래는 tvhProxy를 위해 짜낸 기능이지만 여러모로 유용하게 사용할 수 있을 것이다.


## 덧붙이기

#### tvhProxy 추가 설치

[tvhProxy](https://github.com/jkaberg/tvhProxy)란, tvheadend의 영상 스트림을 Plex의 DVR (녹화)에서 활용할 수 있도록 도와주는 프록시이다. 설치 방법은 역시 동일하게 환경 변수를 통해서 가능하다.
```
TVH_URL=http://username:password@localhost:9981
```
tvheadend와 같이 내장했으므로 localhost가 맞고 그 외 username, password, port를 자신의 환경에 맞게 수정해서 사용한다.

참고로 위의 추가 설치를 활성화 하면 컨테이너 최초 생성시 여러가지 의존성 설치를 위해 시간이 약간 걸린다.

## 자주 묻는 질문

[문제가 발생하면 읽어보세요.](assets/faqs.md)
