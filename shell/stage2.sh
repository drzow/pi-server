#!/bin/bash

# Get command line arguments
HOSTNAME=$1
DOMAIN=$2
if [ -z "${DOMAIN}" ]; then
  echo "Usage: $0 <hostname> <domain>"
  exit 1
fi

# Set the hostname and domain
sudo sed -i -- 's/raspberrypi/${HOSTNAME}/g' /etc/hosts
sudo hostnamectl set-hostname "${HOSTNAME}"

# Set the timezone
# From https://serverfault.com/questions/94991/setting-the-timezone-with-an-automated-script
TIMEZONE="US/Central"
sudo /bin/sh -c 'echo $TIMEZONE > /etc/timezone'
sudo cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Install and run ntp
sudo apt install -y ntp

# Update the system
sudo apt-get update
sudo apt-get -y dist-upgrade

# Install lvm and stuff docker will want
sudo apt -y install btrfs-tools debootstrap lxc rinse fuse fuse-zip fuse2fs fusedav fuseiso fusesmb lvm2

# Install Docker
curl -sSL get.docker.com | sh

# Add pi to the docker group
sudo usermod -a -G docker pi

# Reboot so kernel modules for docker and lvm will run
sudo reboot

