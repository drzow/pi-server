#!/bin/sh
# Get command line arguments
REPOSITORY=$1
OPEMAIL=$2
GITNAME=$3
GITEMAIL=$4

if [ -z "$GITEMAIL" ]; then
  echo "Usage: $0 <1PasswordRepo> <1PasswordEmail> <GitName> <GitEmail>"
  exit 1
fi

# Update the system
sudo apt-get update
sudo apt-get -y upgrade

# Get the 1Password command line tool
OPVER=v0.5.5
wget https://cache.agilebits.com/dist/1P/op/pkg/${OPVER}/op_linux_arm_${OPVER}.zip
# Install it
unzip -o op_linux_arm_${OPVER}.zip
sudo apt-get -y install dirmngr jq
gpg --receive-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22
gpg --verify op.sig op
sudo mv op /usr/local/bin
# Set up 1Password
SESSIONTOKEN=$(op signin ${REPOSITORY}.1password.com ${OPEMAIL} --output=raw)

# Set the pi password
# Get the password from 1Password
PIPASSWD=$(op get item Nextcloud --session=$SESSIONTOKEN | jq '.details.sections | .[] | select(.name == "") | .fields | .[] | select(.n == "password") | .v' | sed -e 's/^"//' -e 's/"$//')
# Set it
sudo chpasswd pi:$PIPASSWD

# Finish setting up git
# TODO: Get these from 1Password
git config --global user.email "${GITEMAIL}"
git config --global user.name "${GITNAME}"
git config credential.helper store

# Install docker
# Mount the data drive
# Download nextcloud docker image
# Run nextcloud docker image
# Download plex docker image
# Run plex docker image
