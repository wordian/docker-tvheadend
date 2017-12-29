
# 자주 묻는 질문

### 업데이트는 어떻게 하나요?
일반적으로 docker image는 제대로 만들어져 있다면 사용자 정보(볼륨 매핑을 해준 곳)와 어플리케이션 본체가 완벽하게 분리되어 있어서 컨테이너를 지웠다가 같은 설정으로 생성/실행했을 때 아무 문제없이 동작해야 합니다.

따라서 컨테이너를 정지 >> 삭제 >> 이미지 업그레이드 (다시 다운로드) >> 같은 설정으로 컨테이너 재생성 >> 실행의 과정을 거치면 업그레이드 된 이미지가 적용 됩니다.

시놀로지 DSM의 경우에는 WEB UI에서 직관적이지만 클릭클릭 여러번 눌러서 진행하실 수 있고,

docker 명령어를 이용하면 SSH에서 다음의 과정을 거쳐서 할 수 있고,

* 컨테이너 정지 ``` docker stop <container name or id>```
* 컨테이너 삭제 ``` docker rm <container name or id>```
* 이미지 업그레이드 ```docker pull wiserain/tvheadend:latest```
* 재생성

docker-compose를 쓰면 좀 더 간단하게 가능합니다.

```bash
docker-compose pull <service name>
docker-compose up -d <service name>
```

컨테이너 이름이나 ID는 ```docker ps``` 명령어로 알 수 있습니다.

### EPG가 공중파 5개 밖에 안나와요!
epg2xml 프로그램 제작자의 의도입니다. [참고](https://github.com/wonipapa/epg2xml/wiki/FAQ#%EC%9D%BC%EB%B0%98)하세요.

### EPG 정보가 이틀치만 가져와 집니다.
역시 위와 같은 답입니다.

### m3u 파일로 mux 등록이 안됩니다.
docker로 돌아가는 tvheadend는 독립된 가상의 공간을 가집니다. 따라서 ```file:///path/to/file.m3u```를 tvheadend에서 등록할 때는 docker container 입장에서 생각해야 합니다. 추천하는 방법은 1) 웹주소로 등록한다. 2) 아니라면 호스트에서 이미 매핑한 ```/docker/tvh/config```나 ```/docker/tvh/epg2xml```에 ```file.m3u``` 파일을 업로드한 다음, tvheadend에서는 ```file:///config/file.m3u```나 ```file:///epg2xml/file.m3u```로 등록하는 것입니다.

경로가 헷갈리면 ssh에서 아래의 명령어를 통해 컨테이너 내부로 진입한 다음 ls와 cd 명령어로 이리저리 둘러보시면 됩니다.

container 내부로 진입하기는 아래 명령어를 치면 됩니다.
```bash
docker exec -it <container name or id> bash
```
docker-compose를 이용하신다면 비슷하게,
```bash
docker-compose exec <service name> bash
```

마지막으로 m3u 파일을 수동으로 편집할 때는 그 형식이 UTF-8 without BOM 이어야 합니다. Notepad++을 이용해서 편집할 것을 추천. 또한 EOL이 unix 형식을 따라야 합니다. (Edit >> EOL Conversion >> Unix (LF)로 변경 가능)

### EPG Grabber Modules이 안보여요.
설정에서 다 보이게 바꿔주세요. [참고](https://www.clien.net/service/board/cm_nas/9913990)

### vaapi 버전은 어떻게 사용하나요?

우선 로컬 호스트에서
```
ls /dev/dri
```
를 실행했을 때 렌더러가 보여야 합니다. 없으면 해당 버전의 이미지를 쓰는 것이 무의미 합니다.

그런 다음 아래의 ```docker-compose.yml```을 통해서 컨테이너를 설정하면 됩니다.

```yaml
version: '2'

services:
  tvh-vaapi:
    container_name: tvh-vaapi
    image: wiserain/tvheadend:vaapi
    network_mode: "host"
    volumes:
      - /volume1/docker/tvh-vaapi/config:/config
      - /volume1/docker/tvh-vaapi/recordings:/recordings
      - /volume1/docker/tvh-vaapi/epg2xml:/epg2xml
      - /tmp/.X11-unix:/tmp/.X11-unix
    devices:
      - "/dev/dri:/dev/dri"
    environment:
      - PUID=0
      - PGID=0
      - DISPLAY=:0
```

가장 중요한 것은 devices 항목을 통해 장치 드라이버(렌더러)를 연결해줘야 하며, PUID와 PGID도 적절한 권한이 필요합니다. 명확한 레퍼런스는 없지만 테스트 결과 보통의 user 권한으로 실행된 docker container는 vaapi 가속을 이용하지 못하는 것을 발견했습니다. 추천하지 않지만 잘 안된다면 root 권한으로 시험해보기 바랍니다.

그런 다음 설정 >> Stream >> Codec Profiles에서 vaapi 관련 코덱을 등록하고 스트림 프로파일에서 연동해서 사용하면 됩니다.
