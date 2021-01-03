#!/bin/sh

ACTUAL_USER=$USER

### General
sudo usermod -aG adbusers,disk,ftp,git,kmem,kvm,network,tty,usbmux,uucp $ACTUAL_USER

### Docker
sudo gpasswd -a $ACTUAL_USER docker
sudo systemctl enable docker
sudo systemctl start docker

