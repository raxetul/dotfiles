#!/usr/bin/env sh
DIR=$(dirname "$0")

. ${DIR}/install-packages.sh
mkdir -p ${DIR}/.installed
zsh
for SH in  ${DIR}/setups/*.sh; do
	echo "Running setup script: ${SH}"
	zsh ${SH}
done