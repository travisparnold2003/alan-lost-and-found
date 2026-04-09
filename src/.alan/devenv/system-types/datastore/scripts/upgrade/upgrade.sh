#!/bin/bash
set -e

BASEDIR=$(dirname "${0}")
SCRIPTDIR=$(cd "${BASEDIR}"; pwd)

if [[ $# -lt 2 ]]
then
	echo "Usage: <old-language-version> <project-path>"
	echo "Example: '106' 'systems/server'"
	echo "IMPORTANT: before performing any upgrades, build your system with the old language version!"
	exit
fi

DS_VERSION=$1
DS_PROJ_PATH=$2

DS_LANG="$SCRIPTDIR/../../language"
TRANS_CONF="$SCRIPTDIR/configs/from-datastore-$DS_VERSION/package"
TEMPLATE_ENGINE="$SCRIPTDIR/../template-engine"

"$TEMPLATE_ENGINE" "$TRANS_CONF" "$DS_PROJ_PATH" "$DS_PROJ_PATH" --
