#!/usr/bin/env zsh

ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.."
ZSH_FILE=${HOME}/.zshrc

# [[ "$(command -v zsh)" ]] && zsh

ZSH_BIN=`which zsh`

if [ "$(sed 's#.*/##' <<<  $SHELL)" != "zsh" ]
then
    zsh # TODO: this has a problem, if shell changes, running this script will stop at this point
    # This part may be irrelevant, shebang should guarantee the shell is being zsh
fi

echo $SHELL
[[ ! -d "${HOME}/.oh-my-zsh" ]] && sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

export ZPLUG_HOME=${ROOTDIR}/.installed/zplug
echo "Zplug installation directory: $ZPLUG_HOME"

[[ ! -d "${ZPLUG_HOME}" ]] && git clone https://github.com/zplug/zplug $ZPLUG_HOME

[[ ! -d "${HOME}/.zsh" ]]  && mkdir -p "${HOME}/.zsh"


AUTO_INSTALLED_USER_LINES_START="### AUTO ADDED USER LINES ############### START"
AUTO_INSTALLED_USER_LINES_END="### AUTO ADDED USER LINES ############### END"
# Activate oh-my-zsh plugins




SETTINGS="$AUTO_INSTALLED_USER_LINES_START
# Don not modifiy this block, add your lines after END line.



for SETTING_FILE in  $ROOTDIR/settings/*.setting;
do
    START_TIME=\$(python3 -c 'import time; print(int(time.time() * 1000))')
    source \${SETTING_FILE}
    END_TIME=\$(python3 -c 'import time; print(int(time.time() * 1000))')
    ELAPSED_TIME=\$((END_TIME - START_TIME))
    echo \"Activated \" \`basename \$SETTING_FILE\` \" in \" \$ELAPSED_TIME \" ms\"
done
fpath+=~/.zsh
$AUTO_INSTALLED_USER_LINES_END"

export USER_ACTIVE_SHELL=$(awk -F: -v user=$USER '$1 == user {print $NF}' /etc/passwd)
echo  "User's active shell is:  $USER_ACTIVE_SHELL"

[[ "$(sed 's#.*/##' <<<  $USER_ACTIVE_SHELL)" != "zsh" ]] && chsh -s ${ZSH_BIN} $USER


SETTINGS=${SETTINGS//\//\\\/}
SETTINGS=${SETTINGS//\$/\\\$}

grep -q "${AUTO_INSTALLED_USER_LINES_START}" "${ZSH_FILE}"; test $? -eq 1 && {
    echo $'\n' >> ${ZSH_FILE}
    echo ${AUTO_INSTALLED_USER_LINES_START} >> ${ZSH_FILE}
    echo ${AUTO_INSTALLED_USER_LINES_END} >> ${ZSH_FILE}
}

perl -i -pe "BEGIN{undef $/;} s/$AUTO_INSTALLED_USER_LINES_START(.|\n)*$AUTO_INSTALLED_USER_LINES_END/$SETTINGS/smg;" ~/.zshrc
perl -i -pe "s/ZSH_THEME=\".*\"/ZSH_THEME=\"agnoster\"/g;" ~/.zshrc




PLUGINS=`perl -pe "s/^/\t/" ${ROOTDIR}/lists/zplug-plugins.list`

echo $PLUGINS

perl -i -pe "BEGIN{undef $/;} s/^plugins=.*\)/plugins=(\n$PLUGINS\n)/smg" ~/.zshrc


# source ${ROOTDIR}/lists/zplug-plugins.list

# zplug install 
# zplug load
echo F

# chmod +x $ZPLUG_HOME/init.zsh
# zsh $ZPLUG_HOME/init.zsh

# echo "ZPLUG is in"  $(which zplug)