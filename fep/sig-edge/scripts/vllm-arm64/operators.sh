#!/usr/bin/env bash
set -euo pipefail
PATH="$WORK_DIR/.venv/bin:$PATH" \
  make -C "$WORK_DIR/flagtree-cpu" PYTHON="$PYTHON"
"$PYTHON" "$SCRIPT_DIR/verify_platform.py"
cd "$WORK_DIR/FlagGems"
"$PYTHON" -m pytest -ra tests/test_arm_w4a8_g128.py \
  --junitxml="$WORK_DIR/logs/flaggems.xml"
"$PYTHON" "$SCRIPT_DIR/check_suite.py" "$WORK_DIR/logs/flaggems.xml" 7
cd "$WORK_DIR/vllm-plugin-FL"
"$PYTHON" -m pytest -ra \
  tests/unit_tests/test_arm_cpu_registration.py \
  tests/unit_tests/patches/test_arm_cpu_gdn.py \
  tests/unit_tests/quantization/test_arm_cpu_w4a8.py \
  --junitxml="$WORK_DIR/logs/plugin.xml"
"$PYTHON" "$SCRIPT_DIR/check_suite.py" "$WORK_DIR/logs/plugin.xml" 16
