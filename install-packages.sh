#!/bin/sh
DIR=$(dirname "$0")

DISTRO="Unknown"
if [[ -f /etc/os-release ]] 
then
    source /etc/os-release
    DISTRO=${ID_LIKE}
    [ -z "${DISTRO}" ] && DISTRO=${ID}
else
    DISTRO=`uname -s`
fi


echo $DISTRO

case $DISTRO in
    debian)
        INSTALL_COMMAND="sudo apt install -y "
        REMOVE_COMMAND="sudo apt remove -y "
        ;;
    alpine)
        INSTALL_COMMAND="sudo apk add "
        REMOVE_COMMAND="sudo apk remove "
        ;;
    arch)
        INSTALL_COMMAND="sudo pacman -S --noconfirm "
        REMOVE_COMMAND="sudo pacman -R "
        ;;

    Darwin)
        DISTRO="macos"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        INSTALL_COMMAND="brew install "
        REMOVE_COMMAND="brew uninstall "
        ;;
    *)
        echo "Your distro(${DISTRO}) is not found, please open an issue in or contribute to https://github.com/raxetul/dotenv"
        exit 1
        ;;
esac

export DISTRO
echo "Distro/OS is: ${DISTRO}"
$INSTALL_COMMAND `cat $DIR/lists/$DISTRO-packages.list`
