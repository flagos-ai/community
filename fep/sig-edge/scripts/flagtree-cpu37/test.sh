#!/usr/bin/env bash
set -euo pipefail
pins_check
PATH="$WORK_DIR/.venv/bin:$PATH" \
  make -C "$WORK_DIR/flagtree-cpu" PYTHON="$PYTHON"
cd "$WORK_DIR"
"$PYTHON" "$SCRIPT_DIR/verify_target.py"
export TRITON_CACHE_DIR
TRITON_CACHE_DIR=$(mktemp -d "$WORK_DIR/triton-jit-XXXXXX")
"$PYTHON" "$SCRIPT_DIR/vector_add.py"
TRITON_CACHE_DIR=$(mktemp -d "$WORK_DIR/flaggems-jit-XXXXXX")
cd "$WORK_DIR/FlagGems"
"$PYTHON" -m pytest -ra tests/test_arm_w4a8_g128.py --junitxml="$WORK_DIR/logs/flaggems.xml"
"$PYTHON" "$SCRIPT_DIR/check_suite.py" "$WORK_DIR/logs/flaggems.xml" 7
