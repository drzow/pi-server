#!/bin/bash
USER=$1
if [ -z "$USER" ]; then
  echo "Usage: $0 <User>"
  exit 1
fi

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
# Create nextcloud docker image
IP=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
if ! docker ps -a | grep nextcloudpi-armhf; then
  docker create -d -p 4443:4443 -p 443:443 -p 80:80 -v /mnt/usbdrive:/data \
    --name nextcloudpi --restart unless-stopped ownyourbits/nextcloudpi-armhf ${IP}
fi
# Start nextcloud docker image
if ! docker ps | grep nextcloudpi-armhf; then
  docker start nextcloudpi
fi

if sudo test -d /mnt/usbdrive/nextcloud/data/${USER}/files/Media/Plex/Config; then
  ./stage4.sh ${USER}
fi

