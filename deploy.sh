#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

DEPLOY_MODE="${1:-migrate}"
TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"
LOG_FILE="$ROOT_DIR/output/DEPLOY_RUN_${TIMESTAMP}.txt"
LATEST_LOG="$ROOT_DIR/output/DEPLOY_RUN_latest.txt"

mkdir -p "$ROOT_DIR/output" "$ROOT_DIR/dist"

# Mirror output to a timestamped log and a stable latest-file for quick inspection.
exec > >(tee -a "$LOG_FILE" "$LATEST_LOG") 2>&1

START_TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "START ${START_TS}"
echo "PWD $(pwd)"
echo "MODE ${DEPLOY_MODE}"

if [[ ! -f "$ROOT_DIR/versions.json" ]]; then
  echo "ERROR versions.json not found in project root: $ROOT_DIR"
  exit 2
fi

run_step() {
  local name="$1"
  shift

  echo "STEP_START ${name}"
  "$@"
  echo "STEP_OK ${name}"
}

run_step fetch "$ROOT_DIR/alan" fetch
run_step build "$ROOT_DIR/alan" build "$ROOT_DIR/dist/project.pkg"
run_step deploy "$ROOT_DIR/alan" deploy "$DEPLOY_MODE"

END_TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "END ${END_TS}"
echo "EXIT_CODE 0"
