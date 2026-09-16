#!/usr/bin/env bash
set -euo pipefail
source "$SCRIPT_DIR/pins.env"
source "$SCRIPT_DIR/fetch.sh"
export WORK_DIR="${WORK_DIR:-$HOME/arm64-vllm024-test}"
export MODEL_ROOT="${MODEL_ROOT:-$HOME/Models}"
export W4_SOURCE="${W4_SOURCE:-$MODEL_ROOT/MiniCPM5-2B-W4A8-arm-FlagOS}"
export W4_PACKED="${W4_PACKED:-$MODEL_ROOT/MiniCPM5-2B-W4A8-arm-FlagOS-packed}"
export W8_MODEL="${W8_MODEL:-$MODEL_ROOT/MiniCPM5-2B-W8A8-arm-FlagOS}"
export A720_CORES="${A720_CORES:-0,1,6,7,8,9,10,11}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-8}" MKL_NUM_THREADS="${MKL_NUM_THREADS:-8}"
export VLLM_CPU_OMP_THREADS_BIND="$A720_CORES"
export VLLM_CPU_KVCACHE_SPACE="${VLLM_CPU_KVCACHE_SPACE:-1}"
export VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS="${VLLM_EXECUTE_MODEL_TIMEOUT_SECONDS:-1800}"
export TRITON_CACHE_DIR="${TRITON_CACHE_DIR:-$WORK_DIR/.cache/triton-2c35990}"
export TORCHINDUCTOR_CACHE_DIR="${TORCHINDUCTOR_CACHE_DIR:-$WORK_DIR/.cache/inductor-2c35990}"
export VLLM_CACHE_ROOT="${VLLM_CACHE_ROOT:-$WORK_DIR/.cache/vllm-2c35990}"
export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1 VLLM_PLUGINS=fl
unset VLLM_VENDOR
export TOKENIZER_SHA W8_WEIGHT_SHA W4_WEIGHT_SHA PACKED_WEIGHT_SHA
PYTHON="$WORK_DIR/.venv/bin/python"

fail() { echo "ERROR: $*" >&2; exit 1; }
host_check() {
  test "$(uname -s)" = Linux || fail 'Linux is required'
  test "$(uname -m)" = aarch64 || fail 'aarch64 is required'
  uname -a
  free -h
  df -h "$HOME"
  lscpu -e=CPU,CORE,ONLINE,MAXMHZ
  lscpu | grep -E 'Architecture|Flags'
}
clean_source() {
  test "$(git -C "$1" rev-parse HEAD)" = "$2" || fail "wrong revision: $1"
  git -C "$1" diff --exit-code
  git -C "$1" diff --cached --exit-code
}
runtime() {
  test -x "$PYTHON" || fail 'run setup first'
  clean_source "$WORK_DIR/vllm" "$VLLM_SHA"
  clean_source "$WORK_DIR/flagtree-cpu" "$TREE_SHA"
  clean_source "$WORK_DIR/FlagGems" "$GEMS_SHA"
  clean_source "$WORK_DIR/vllm-plugin-FL" "$PLUGIN_SHA"
  mkdir -p "$WORK_DIR/logs" "$TRITON_CACHE_DIR" "$TORCHINDUCTOR_CACHE_DIR" "$VLLM_CACHE_ROOT"
  cd "$WORK_DIR/vllm-plugin-FL"
}
model_kind() {
  export MODEL_KIND="$1"
  case "$MODEL_KIND" in
    w4) export MODEL_DIR="$W4_PACKED" CONTEXT_LIMIT=256 ;;
    w8) export MODEL_DIR="$W8_MODEL" CONTEXT_LIMIT=512 ;;
    *) fail 'model must be w4 or w8' ;;
  esac
}
logged() { "$@" 2>&1 | tee "$WORK_DIR/logs/$LOG_NAME.log"; }
