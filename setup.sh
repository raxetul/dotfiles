#!/bin/sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source /etc/os-release

 . ${DIR}/install-packages.sh
mkdir -p ${DIR}/.installed
for SH in  ${DIR}/setups/*.sh; do
	. ${SH}
done