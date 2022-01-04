#!/bin/sh
DIR=$(dirname "$0")

. ${DIR}/install-packages.sh
mkdir -p ${DIR}/.installed
for SH in  ${DIR}/setups/*.sh; do
	echo "Running setup script: ${SH}"
	. ${SH}
done