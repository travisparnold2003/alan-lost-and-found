set -e

BASEDIR=$(dirname "${0}")
SCRIPTDIR=$(cd "${BASEDIR}"; pwd)

if [[ $# -lt 2 ]]
then
	echo "Usage: <transformation> <project-path>"
	echo "Example: 'to-base' 'models/model'"
	exit
fi

MODEL_TRANS=$1
MODEL_PROJ_PATH=$2

MODEL_LANG="$SCRIPTDIR/../../language"
TRANS_CONF="$SCRIPTDIR/configs/$MODEL_TRANS/package"
TEMPLATE_ENGINE="$SCRIPTDIR/template-engine"

"$TEMPLATE_ENGINE" "$TRANS_CONF" "$MODEL_PROJ_PATH" "$MODEL_PROJ_PATH" --
