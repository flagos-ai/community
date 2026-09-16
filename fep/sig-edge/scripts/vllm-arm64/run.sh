#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
usage() {
  cat <<'EOF'
Usage: bash run.sh setup | test w4|w8
       bash run.sh operators | models [w4|w8|all]
       bash run.sh prewarm w4|w8
       bash run.sh smoke w4|w8 | bench w4|w8 | serve w4|w8
Defaults: Debian 13/aarch64, ~/arm64-vllm024-test, ~/Models, CIX P1 A720 cores.
Override WORK_DIR, MODEL_ROOT, A720_CORES, OMP_NUM_THREADS and PORT as needed.
Cold Triton compilation can take over 15 minutes. Caches are retained.
smoke/bench start their own localhost server and stop it after testing.
EOF
}
ACTION=${1:-help}
case "$ACTION" in help|-h|--help) usage; exit 0;; esac
case "$ACTION" in setup|test|operators|models|prewarm|smoke|bench|serve) ;; *) usage; exit 2;; esac
case "$ACTION" in
  test|prewarm|smoke|bench|serve) case "${2:-}" in w4|w8) ;; *) usage; exit 2;; esac ;;
  models) case "${2:-all}" in w4|w8|all) ;; *) usage; exit 2;; esac ;;
esac
source "$SCRIPT_DIR/common.sh"
mkdir -p "$WORK_DIR/logs"
LOG_NAME="$ACTION-${2:-all}"
if [ "$ACTION" = setup ]; then
  logged source "$SCRIPT_DIR/setup.sh"
  exit 0
fi
runtime
case "$ACTION" in
  test)
    for phase in operators models prewarm smoke; do
      echo "Running $phase for $2"
      if [ "$phase" = operators ]; then
        bash "$SCRIPT_DIR/run.sh" "$phase"
      else
        bash "$SCRIPT_DIR/run.sh" "$phase" "$2"
      fi
    done
    ;;
  operators) logged source "$SCRIPT_DIR/operators.sh" ;;
  models) logged source "$SCRIPT_DIR/models.sh" "${2:-all}" ;;
  prewarm)
    model_kind "${2:-}"
    "$PYTHON" "$SCRIPT_DIR/verify_model.py"
    echo "Prewarming $MODEL_KIND; retain $TRITON_CACHE_DIR. First-use compilation can take over 15 minutes."
    for pass in prepare restart; do
      LOG_NAME="prewarm-$MODEL_KIND-$pass"
      logged env VLLM_ENABLE_V1_MULTIPROCESSING=0 taskset -c "$A720_CORES" \
        "$PYTHON" -u "$SCRIPT_DIR/prewarm_model.py"
    done
    ;;
  smoke|bench|serve)
    model_kind "${2:-}"
    "$PYTHON" "$SCRIPT_DIR/verify_model.py"
    logged "$PYTHON" -u "$SCRIPT_DIR/http_test.py" "$ACTION"
    ;;
esac
