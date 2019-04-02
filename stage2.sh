#!/bin/bash
# Get command line arguments
REPOSITORY=$1
OPEMAIL=$2

if [ -z "${OPEMAIL}" ]; then
  echo "Usage: $0 <1PasswordRepo> <1PasswordEmail>"
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
echo pi:${PIPASSWD} | sudo chpasswd

# Finish setting up git
GITUSER=$(op get item GitHub --session=$SESSIONTOKEN | jq '.details.fields | .[] | select(.name == "username") | .value' | sed -e 's/^"//' -e 's/"$//')
GITEMAIL=$(op get item GitHub --session=$SESSIONTOKEN | jq '.details.sections | .[] | select(.title == "Additional Info") | .fields | .[] | select(.t == "email") | .v' | sed -e 's/^"//' -e 's/"$//')
GITNAME=$(op get item GitHub --session=$SESSIONTOKEN | jq '.details.sections | .[] | select(.title == "Additional Info") | .fields | .[] | select(.t == "name") | .v' | sed -e 's/^"//' -e 's/"$//')
GITTOKEN=$(op get item GitHub --session=$SESSIONTOKEN | jq '.details.sections | .[] | select(.title == "Additional Info") | .fields | .[] | select(.t == "token") | .v' | sed -e 's/^"//' -e 's/"$//')
git config --global user.email "${GITEMAIL}"
git config --global user.name "${GITNAME}"
git config credential.helper store
GITURL=$(git remote get-url --push origin)
# From https://stackoverflow.com/questions/6174220/parse-url-in-shell-script
# extract the protocol
GITPROTO="$(echo ${GITURL} | grep :// | sed -e's,^\(.*://\).*,\1,g')"
# remove the protocol
GITREMAIN="${GITURL/$GITPROTO/}"
# extract the user (if any)
GITURLUSER="$(echo ${GITREMAIN} | grep @ | cut -d@ -f1)"
# extract the host
GITHOST="$(echo ${GITREMAIN/$GITURLUSER@/} | cut -d/ -f1)"
# extract the path (if any)
GITPATH="$(echo ${GITREMAIN} | grep / | cut -d/ -f2-)"
NEWGITURL="https://${GITUSER}:${GITTOKEN}@${GITHOST}/${GITPATH}"
git push -n ${NEWGITURL}

# Install lvm and stuff docker will want
sudo apt -y install btrfs-tools debootstrap lxc rinse fuse fuse-zip fuse2fs fusedav fuseiso fusesmb lvm2

# Install Docker
curl -sSL get.docker.com | sh

# Add pi to the docker group
sudo usermod -a -G docker pi

# Reboot so kernel modules for docker and lvm will run
sudo reboot

