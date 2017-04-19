# docker-tvheadend

docker container with Korean EPG grabber based on
- [linuxserver/tvheadend](https://hub.docker.com/r/linuxserver/tvheadend/)
- Korean EPG grabber by [epg2xml](https://github.com/wonipapa/epg2xml) and internal [tv_grab_file](https://github.com/nurtext/tv_grab_file_synology)
- [FFmpeg Static Builds](https://johnvansickle.com/ffmpeg/)


## Usage

```
docker run -d \
    --name=<container name> \
    --network=host \
    -v <path for recordings>:/recordings \
    -v <path for config>:/config \
    -e TZ=<timezone> \
    -e PUID=<UID for user> \
    -e PGID=<GID for user> \
    wiserain/tvheadend
```

```
version: '2'
services:
  <service name>:
    container_name: <container name>
    image: wiserain/tvheadend:latest
    restart: always
    network_mode: "host"
    volumes:
      - <path for config>:/config
      - <path for recordings>:/recordings
    environment:
      - PUID=<UID for user>
      - PGID=<GID for user>
      - TZ=Asia/Seoul
```
By default, ```TZ``` is set to ```Asia/Seoul``` for Korean users. After container runs, you can access WEBUI via ```http://myip:9981/```. You may also find the internal epg grabber for three different iptv service providers, e.g. KT, SK, and LG, in the menu ```Configuration > Channel / EPG > EPG Grabber Modules```. For more details in Korean, please refer to [this article](http://wiserain.net/1038).

## Updates
- 2017-04-19: apply changes from linuxserver/docker-tvheadend ```use repo version of gnu-libiconv ...```, update epg2xml to 1.1.7, and make FFMPEGBIN optional
- 2017-04-04: add ```tv_grab_kr_epg2xml``` and ```tv_grab_kr_mc2xml```
- 2017-xx-xx: initial build

## Further information

**tvheadend**
- [github repository](https://github.com/tvheadend/tvheadend)
- [Build guide on clean Ubuntu](https://tvheadend.org/boards/4/topics/24116)

**HW Acceleration**
- [Using Hardware Acceleration with Docker](http://wiki.ros.org/docker/Tutorials/Hardware%20Acceleration)
- [Tvheadend and HW Acceleration Intel Quick Sync Video](http://www.luispa.com/archivos/4876)

**mc2xml**
- [mc2xml](http://mc2xml.hosterbox.net/)
- [tips and tricks for mc2xml](https://forum.team-mediaportal.com/threads/mc2xml-what-are-your-usage-tips-tricks.59374/)

**References**
- linuxserver/tvheadend on [github](https://github.com/linuxserver/docker-tvheadend) and [dockerhub](https://hub.docker.com/r/linuxserver/tvheadend/)
- tobbenb/tvheadend-unstable on [github](https://github.com/tobbenb/docker-containers/tree/master/tvheadend-unstable) and ~~[dockerhub](https://hub.docker.com/r/tobbenb/tvheadend-unstable/)~~
