#!/bin/sh
# Enable ssh
sudo touch /boot/ssh

# Fix the keyboard layout
sudo cp keyboard /etc/default
reboot
