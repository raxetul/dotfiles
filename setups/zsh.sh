#!/usr/bin/env zsh
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.."
ZSH_FILE=${HOME}/.zshrc

ZSH_BIN=`which zsh`
echo $DISTRO
if [[ "$DISTRO" != "Darwin" ]];
then
    zsh
fi
AUTO_INSTALLED_USER_LINES_START="### AUTO ADDED USER LINES ############### START"
AUTO_INSTALLED_USER_LINES_END="### AUTO ADDED USER LINES ############### END"

# Activate oh-my-zsh plugins
#PLUGINS=`perl -pe "s/^/\t/" ${ROOTDIR}/lists/oh-my-zsh-plugins.list`
#perl -i -pe "BEGIN{undef $/;} s/^plugins=.*\)/plugins=(\n$PLUGINS\n)/smg" ~/.zshrc

[[ ! -d "${HOME}/.oh-my-zsh" ]] && sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

export ZPLUG_HOME=${ROOTDIR}/.installed/zplug
[[ ! -d "${ZPLUG_HOME}" ]] && git clone https://github.com/zplug/zplug $ZPLUG_HOME


SETTINGS="$AUTO_INSTALLED_USER_LINES_START
# Don not modifiy this block, add your lines after END line.
source $ROOTDIR/.installed/zplug/init.zsh

for SETTING_FILE in  $ROOTDIR/settings/*.setting;
do
    START_TIME=\$(python3 -c 'import time; print(int(time.time() * 1000))')
    source \${SETTING_FILE}
    END_TIME=\$(python3 -c 'import time; print(int(time.time() * 1000))')
    ELAPSED_TIME=\$((END_TIME - START_TIME))
    echo \"Activated \" \`basename \$SETTING_FILE\` \" in \" \$ELAPSED_TIME \" ms\"
done

$AUTO_INSTALLED_USER_LINES_END"

chsh -s ${ZSH_BIN} $USER

SETTINGS=${SETTINGS//\//\\\/}
SETTINGS=${SETTINGS//\$/\\\$}

grep -q "${AUTO_INSTALLED_USER_LINES_START}" "${ZSH_FILE}"; test $? -eq 1 && {
    echo $'\n' >> ${ZSH_FILE}
    echo ${AUTO_INSTALLED_USER_LINES_START} >> ${ZSH_FILE}
    echo ${AUTO_INSTALLED_USER_LINES_END} >> ${ZSH_FILE}
}

perl -i -pe "BEGIN{undef $/;} s/$AUTO_INSTALLED_USER_LINES_START(.|\n)*$AUTO_INSTALLED_USER_LINES_END/$SETTINGS/smg;" ~/.zshrc
perl -i -pe "s/ZSH_THEME=\".*\"/ZSH_THEME=\"agnoster\"/g;" ~/.zshrc

echo "ZPLUG_HOME is: ${ZPLUG_HOME}"

source $ZPLUG_HOME/init.zsh


source ${ROOTDIR}/lists/zplug-plugins.list
zplug install 
zplug load
