#!/bin/bash
set -e

BASEDIR=$(dirname "${0}")
SCRIPTDIR=$(cd "${BASEDIR}"; pwd)

if [[ $# -lt 1 ]]
then
	echo "Usage: <path to datastore system>"
	echo "Example: 'systems/server'"
	exit 1
fi

if [[ -f "$1/model" ]]; then
	MODEL="$1/model"
elif [[ -f "$1/model.link" ]]; then
	MODEL="$1/$(cat "$1/model.link")"
else
	echo "Cannot find model"
	exit 1
fi

TRANS_CONF="$SCRIPTDIR/configs/consumed_interfaces_mapping/package"
TEMPLATE_ENGINE="$SCRIPTDIR/template-engine"

echo "$TEMPLATE_ENGINE" "$TRANS_CONF" "$MODEL" "$1"/interfaces/consuming/ --
"$TEMPLATE_ENGINE" "$TRANS_CONF" "$MODEL" "$1"/interfaces/consuming/ --