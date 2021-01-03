#!/bin/sh
DIR=$(dirname "$0")

source /etc/os-release

DISTRO=${ID_LIKE}
[ -z "${DISTRO}" ] && DISTRO=${ID}

echo $DISTRO

case $DISTRO in
    debian)
        INSTALL_COMMAND="apt install -y "
        REMOVE_COMMAND="apt remove -y "
        ;;
    alpine)
        INSTALL_COMMAND="apk add "
        REMOVE_COMMAND="apk remove "
        ;;
    arch)
        INSTALL_COMMAND="pacman -S --noconfirm "
        REMOVE_COMMAND="pacman -R "
        ;;
    *)
        echo "Your distro is not found, please open an issue in or contribute to https://github.com/raxetul/dotenv"
        exit 1
        ;;
esac

sudo $INSTALL_COMMAND `cat $DIR/lists/$DISTRO-packages.list`
