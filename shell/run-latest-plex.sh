#!/bin/bash
# From https://stackoverflow.com/questions/26423515/how-to-automatically-update-your-docker-containers-if-base-images-are-updated
set -e
REGISTRY="linuxserver"
BASE_IMAGE="plex"
IMAGE="$REGISTRY/$BASE_IMAGE"
CID=$(docker ps | grep $IMAGE | awk '{print $1}')
docker pull $IMAGE

for im in $CID; do
     LATEST=$(docker inspect --format "{{.Id}}" $IMAGE)
     RUNNING=$(docker inspect --format "{{.Image}}" $im)
     NAME=$(docker inspect --format '{{.Name}}' $im | sed "s/\///g")
     echo "Latest:" $LATEST
     echo "Running:" $RUNNING
     if [ "$RUNNING" != "$LATEST" ];then
         echo "upgrading $NAME"
         docker stop $NAME
         docker rm -f $NAME
         USER="zow"
         docker create --name=$NAME --net=host -e PUID=33 -e PGID=33 -e VERSION=docker -v /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/Config:/config -v /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/TV:/data/tvshows -v /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/Movies:/data/movies -v /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/Transcoding:/transcode --restart unless-stopped $IMAGE
         docker start $NAME
     else
         echo "$NAME up to date"
     fi
done
