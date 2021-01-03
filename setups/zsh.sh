#!/usr/bin/env zsh
ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.."
ZSH_FILE=${HOME}/.zshrc

AUTO_INSTALLED_USER_LINES_START="### AUTO ADDED USER LINES ############### START"
AUTO_INSTALLED_USER_LINES_END="### AUTO ADDED USER LINES ############### END"

# Activate oh-my-zsh plugins
#PLUGINS=`perl -pe "s/^/\t/" ${ROOTDIR}/lists/oh-my-zsh-plugins.list`
#perl -i -pe "BEGIN{undef $/;} s/^plugins=.*\)/plugins=(\n$PLUGINS\n)/smg" ~/.zshrc

export ZPLUG_HOME=${ROOTDIR}/.installed/zplug
[[ ! -d "${ZPLUG_HOME}" ]] && git clone https://github.com/zplug/zplug $ZPLUG_HOME


SETTINGS="$AUTO_INSTALLED_USER_LINES_START
# Don not modifiy this block, add your lines after END line.
source $ROOTDIR/.installed/zplug/init.zsh

for SETTING_FILE in  $ROOTDIR/settings/*.setting;
do
    source \${SETTING_FILE}
done

$AUTO_INSTALLED_USER_LINES_END"

SETTINGS=${SETTINGS//\//\\\/}
SETTINGS=${SETTINGS//\$/\\\$}

grep -q "${AUTO_INSTALLED_USER_LINES_START}" "${ZSH_FILE}"; test $? -eq 1 && {
    echo $'\n' >> ${ZSH_FILE}
    echo ${AUTO_INSTALLED_USER_LINES_START} >> ${ZSH_FILE}
    echo ${AUTO_INSTALLED_USER_LINES_END} >> ${ZSH_FILE}
}

perl -i -pe "BEGIN{undef $/;} s/$AUTO_INSTALLED_USER_LINES_START(.|\n)*$AUTO_INSTALLED_USER_LINES_END/$SETTINGS/smg;" ~/.zshrc
perl -i -pe "s/ZSH_THEME=\".*\"/ZSH_THEME=\"agnoster\"/g;" ~/.zshrc

echo $ZPLUG_HOME
source $ZPLUG_HOME/init.zsh


source ${ROOTDIR}/lists/zplug-plugins.list
zplug install 
zplug load