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


# Black:          #1E2127        Black:          #000000
# Bright Black:   #5C6370        Bright Black:   #383A42
# Red:            #E06C75        Red:            #E45649
# Bright Red:     #E06C75        Bright Red:     #E45649
# Green:          #98C379        Green:          #50A14F
# Bright Green:   #98C379        Bright Green:   #50A14F
# Yellow:         #D19A66        Yellow:         #986801
# Bright Yellow:  #D19A66        Bright Yellow:  #986801
# Blue:           #61AFEF        Blue:           #4078F2
# Light Blue:     #61AFEF        Light Blue:     #4078F2
# Magenta:        #C678DD        Magenta:        #A626A4
# Light Magenta:  #C678DD        Light Magenta:  #A626A4
# Cyan:           #56B6C2        Cyan:           #0184BC
# Light Cyan:     #56B6C2        Light Cyan:     #0184BC
# White:          #ABB2BF        White:          #A0A1A7
# Bright White:   #FFFFFF        Bright White:   #FFFFFF
# Text:           #ABB2BF        Text:           #383A42
# Bold Text:      #ABB2BF        Bold Text:      #A0A1A7
# Selection:      #3A3F4B        Selection:      #3A3F4B
# Cursor:         #5C6370        Cursor:         #383A42
# Background:     #1E2127        Background:     #F9F9F9