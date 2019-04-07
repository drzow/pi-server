#!/bin/bash

USER=$1
if [ -z "$USER" ]; then
  echo "Usage: $0 <User>"
  exit 1
fi

# Download plex docker image
docker pull linuxserver/plex
# Create plex docker image
if ! docker ps -a | grep plex; then
  docker run -d --name=plex --net=host -e PUID=33 -e PGID=33 -e VERSION=docker \
    -v /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/Config:/config \
    -v /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/TV:/data/tvshows \
    -v /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/Movies:/data/movies \
    -v /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/Transcoding:/transcode \
    --restart unless-stopped linuxserver/plex
fi
# Start plex docker image
if ! docker ps | grep plex; then
  docker start plex
fi

