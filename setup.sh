#!/bin/sh
DIR=$(dirname "$0")

source /etc/os-release

. ${DIR}/install-packages.sh
mkdir -p ${DIR}/.installed
for SH in  ${DIR}/setups/*.sh; do
	. ${SH}
done