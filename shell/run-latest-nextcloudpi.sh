#!/bin/bash
# From https://stackoverflow.com/questions/26423515/how-to-automatically-update-your-docker-containers-if-base-images-are-updated
set -e
REGISTRY="ownyourbits"
BASE_IMAGE="nextcloudpi-armhf"
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
         IP=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
         docker create -p 4443:4443 -p 443:443 -p 80:80 -v /mnt/usbdrive:/data --name $NAME --restart unless-stopped ownyourbits/nextcloudpi-armhf ${IP}
         docker start $NAME
     else
         echo "$NAME up to date"
     fi
done
