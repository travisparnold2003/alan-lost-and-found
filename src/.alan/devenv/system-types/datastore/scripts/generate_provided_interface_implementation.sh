#!/bin/bash
set -e

BASEDIR=$(dirname "${0}")
SCRIPTDIR=$(cd "${BASEDIR}"; pwd)

if [[ $# -lt 2 ]]
then
	echo "Usage: <path to an interface project directory containing an interface.alan file> <output folder for writing the implementation.alan file>"
	echo "Example: 'interfaces/provide-int' 'systems/server/interfaces/providing/provide-int'"
	exit 1
fi

PROJ_PATH=$1
OUT_PATH=$2

TRANS_CONF="$SCRIPTDIR/configs/provided_interface_implementation/package"
TEMPLATE_ENGINE="$SCRIPTDIR/template-engine"

"$TEMPLATE_ENGINE" "$TRANS_CONF" "$PROJ_PATH" "$OUT_PATH" --
