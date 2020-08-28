#!/bin/bash -e

# Get command line arguments
REPOSITORY=$1
OPEMAIL=$2
USER=$3
if [ -z "$USER" ]; then
  echo "Usage: $0 <1PasswordRepo> <1PasswordEmail> <User>"
  exit 1
fi

# Get the 1Password command line tool
if ! [ -x /usr/local/bin/op ]; then
  OPVER=v0.8.0
  wget https://cache.agilebits.com/dist/1P/op/pkg/${OPVER}/op_linux_arm_${OPVER}.zip
  # Install it
  unzip -o op_linux_arm_${OPVER}.zip
  sudo apt-get -y install dirmngr jq
  gpg --keyserver hkps://keyserver.ubuntu.com --receive-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22
  gpg --verify op.sig op
  sudo mv op /usr/local/bin
fi
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

# Download plex docker image
docker pull linuxserver/plex
# Create plex docker image
if ! docker ps -a | grep plex; then
  docker create --name=plex --net=host -e PUID=33 -e PGID=33 -e VERSION=docker \
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


# Download samba docker image
docker pull trnape/rpi-samba
# Create samba docker image
if ! docker ps -a | grep samba; then
  BUUSER=$(op get item Nextcloud --session=$SESSIONTOKEN | jq '.details.sections | .[] | select(.title == "Backups") | .fields | .[] | select(.t == "username") | .v' | sed -e 's/^"//' -e 's/"$//')
  BUPASS=$(op get item Nextcloud --session=$SESSIONTOKEN | jq '.details.sections | .[] | select(.title == "Backups") | .fields | .[] | select(.t == "password") | .v' | sed -e 's/^"//' -e 's/"$//')
  docker create --name samba -p 445:445 \
    -v /mnt/backups:/share/backups \
    trnape/rpi-samba \
    -u "${BUUSER}:${BUPASS}" \
    -s "Backup directory:/share/backups:rw:${BUUSER}"
fi
# Start samba docker image
if ! docker ps | grep samba; then
  docker start samba
fi

