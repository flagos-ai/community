#!/usr/bin/env bash
set -euo pipefail
source "$SCRIPT_DIR/fetch.sh"
export WORK_DIR="${WORK_DIR:-$HOME/flagtree-cpu-3.7-test}"
export BUILD_JOBS="${BUILD_JOBS:-4}"
export FLAGGEMS_VENDOR=arm TRITON_CPU_BACKEND=1
PYTHON="$WORK_DIR/.venv/bin/python"
TREE_SHA=2c35990a30e96665f8f9b5e158562288b4011048
GEMS_SHA=1fda4b11ae528c02ae5187cda551af4a61a514c5
LLVM_SHA=87717bf9f81f7b29466c5d9a30a3453bdfc93941
SLEEF_SHA=93f04d869471ce4d007abaebb8c6a7bc62749f61
fail() { echo "ERROR: $*" >&2; exit 1; }
pins_check() {
  test "$(git -C "$WORK_DIR/flagtree-cpu" rev-parse HEAD)" = "$TREE_SHA"
  test "$(cat "$WORK_DIR/flagtree-cpu/cmake/llvm-hash.txt")" = "$LLVM_SHA"
  test "$(git -C "$WORK_DIR/flagtree-cpu/third_party/sleef" rev-parse HEAD)" = "$SLEEF_SHA"
  test "$(git -C "$WORK_DIR/FlagGems" rev-parse HEAD)" = "$GEMS_SHA"
  for repo in flagtree-cpu FlagGems; do
    git -C "$WORK_DIR/$repo" diff --exit-code
    git -C "$WORK_DIR/$repo" diff --cached --exit-code
  done
  echo "source pins: FlagTree=$TREE_SHA FlagGems=$GEMS_SHA LLVM=$LLVM_SHA SLEEF=$SLEEF_SHA"
}
