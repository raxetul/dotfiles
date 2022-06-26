#!/bin/sh

echo C

ACTUAL_USER=$USER
if [[ $DISTRO != "Darwin" ]];
then
    echo "OS is a GNU-Linux distro, setting up user"
    ### General
    sudo usermod -aG adbusers,disk,ftp,git,kmem,kvm,network,tty,usbmux,uucp $ACTUAL_USER

    ### Docker
    sudo gpasswd -a $ACTUAL_USER docker
    sudo systemctl enable docker
    sudo systemctl start docker
else 
    echo "OS is not a GNU-Linux distro(is a ${DISTRO}), skipping user setup"
fi
