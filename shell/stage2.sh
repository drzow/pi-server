#!/bin/bash -e

# Set the timezone
# From https://serverfault.com/questions/94991/setting-the-timezone-with-an-automated-script
TIMEZONE="US/Central"
sudo /bin/sh -c 'echo $TIMEZONE > /etc/timezone'
sudo cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

# Disable IPv6 (you can take this out if it works for you)
sudo -E sh -c 'echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf'
sudo sysctl -p

# Install and run ntp
sudo apt install -y ntp

# Substitute a close mirror for raspbian.raspberrypi.org
# We should immediately update after doing this
sudo sed -i -- 's/raspbian.raspberrypi.org/plug-mirror.rcac.purdue.edu/g' /etc/apt/sources.list

# Update the system
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade
sudo apt -y autoremove

# Install lvm and stuff docker will want
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install btrfs-progs debootstrap lxc rinse fuse fuse-zip fuse2fs fusedav fuseiso fusesmb lvm2 apt-transport-https

# Docker seems to fail if installed in rapid succession
sleep 60

# Install Docker
curl -sSL get.docker.com | sh

# Add pi to the docker group
sudo usermod -a -G docker pi

# Reboot so kernel modules for docker and lvm will run
sudo reboot

