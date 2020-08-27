#!/bin/sh

# Get command line arguments
HOSTNAME=$1
DOMAIN=$2
if [ -z "${DOMAIN}" ]; then
  echo "Usage: $0 <hostname> <domain>"
  exit 1
fi

# Enable ssh
sudo touch /boot/ssh

# Fix the keyboard layout
sudo cp keyboard /etc/default

# Set the hostname and domain
sudo sed -i -- 's/raspberrypi/${HOSTNAME} ${HOSTNAME}\.${DOMAIN}/g' /etc/hosts
sudo hostnamectl set-hostname "${HOSTNAME}"

# And reboot
sudo reboot

