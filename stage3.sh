#!/bin/bash

# Mount the data drive
sudo vgchange -ay nc_data
sudo mkdir -p /mnt/usbdrive
if ! grep usbdrive /etc/fstab; then
  sudo /bin/bash -c 'echo -e "/dev/nc_data/lv_data\t/mnt/usbdrive\tbtrfs\tdefaults,noatime\t0\t2" >> /etc/fstab'
fi
if ! mount | grep usbdrive; then
  sudo mount /mnt/usbdrive
fi

# Download nextcloud docker image
docker pull ownyourbits/nextcloudpi-armhf
# Run nextcloud docker image
IP=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
if ! docker ps | grep nextcloudpi-armhf; then
  docker run -d -p 4443:4443 -p 443:443 -p 80:80 -v /mnt/usbdrive:/data --name nextcloudpi --restart unless-stopped ownyourbits/nextcloudpi-armhf ${IP}
fi

# Download plex docker image
docker pull linuxserver/plex
# Run plex docker image
if ! docker ps | grep plex; then
  docker run --name=plex --net=host -e PUID=33 -e PGID=33 -e VERSION=docker -v /mnt/usbdrive/nextcloud/data/zow/files/Media/Plex/Config:/config -v /mnt/usbdrive/nextcloud/data/zow/files/Media/Plex/TV:/data/tvshows -v /mnt/usbdrive/nextcloud/data/zow/files/Media/Plex/Movies:/data/movies -v /mnt/usbdrive/nextcloud/data/zow/files/Media/Plex/Transcoding:/transcode --restart unless-stopped linuxserver/plex
fi
