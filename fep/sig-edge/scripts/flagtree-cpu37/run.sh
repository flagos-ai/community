#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
case "${1:-help}" in
  help|-h|--help)
    echo 'Usage: bash run.sh setup | test'
    echo 'Defaults: Debian 13/aarch64, ~/flagtree-cpu-3.7-test, BUILD_JOBS=4.'
    exit 0 ;;
  setup|test) ACTION=$1 ;;
  *) echo 'Usage: bash run.sh setup | test' >&2; exit 2 ;;
esac
source "$SCRIPT_DIR/common.sh"
mkdir -p "$WORK_DIR/logs"
case "$ACTION" in
  setup) source "$SCRIPT_DIR/setup.sh" 2>&1 | tee "$WORK_DIR/logs/setup.log" ;;
  test)
    test -x "$PYTHON" || fail 'run setup first'
    source "$SCRIPT_DIR/test.sh" 2>&1 | tee "$WORK_DIR/logs/test.log" ;;
esac
