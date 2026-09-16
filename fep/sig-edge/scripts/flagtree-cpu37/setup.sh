#!/usr/bin/env bash
set -euo pipefail
test "$(uname -s)" = Linux && test "$(uname -m)" = aarch64 || fail 'Linux aarch64 is required'
source /etc/os-release
test "$ID" = debian && test "$VERSION_ID" = 13 || fail 'setup targets Debian 13'
if [ "${SKIP_SYSTEM_PACKAGES:-0}" != 1 ]; then
  APT=(apt-get)
  if [ "$EUID" -ne 0 ]; then
    command -v sudo >/dev/null || fail 'sudo is required for system packages; ask the administrator to install prerequisites'
    APT=(sudo apt-get)
  fi
  "${APT[@]}" update
  "${APT[@]}" install -y git curl ca-certificates procps util-linux build-essential \
    ninja-build cmake zlib1g-dev libxml2-dev pipx
fi
uname -a
free -h
df -h "$HOME"
LC_ALL=C lscpu | grep -E 'Architecture|Flags'
export PATH="$HOME/.local/bin:$PATH"
uv() {
  if [ -x "$HOME/.local/bin/uv" ] && [ "$("$HOME/.local/bin/uv" --version)" = 'uv 0.8.24' ]; then
    "$HOME/.local/bin/uv" "$@"
  else
    command pipx run --spec 'uv==0.8.24' uv "$@"
  fi
}
uv python install 3.11.13
fetch_commit https://github.com/flagos-ai/flagtree-cpu.git flagtree-cpu "$TREE_SHA"
fetch_commit https://github.com/flagos-ai/FlagGems.git FlagGems "$GEMS_SHA"
git -C "$WORK_DIR/flagtree-cpu" submodule update --init --recursive
cd "$WORK_DIR"
if [ ! -x "$PYTHON" ]; then uv venv --python 3.11.13 .venv; fi
source "$WORK_DIR/.venv/bin/activate"
uv pip install -r flagtree-cpu/python/requirements.txt
uv pip install --extra-index-url https://download.pytorch.org/whl/cpu \
  --index-strategy unsafe-best-match 'torch==2.11.0+cpu' 'numpy==2.3.5' pytest
TRITON_HOME="$WORK_DIR/.triton-build" TRITON_BUILD_PROTON=OFF MAX_JOBS="$BUILD_JOBS" \
  uv pip install --no-build-isolation --editable "$WORK_DIR/flagtree-cpu"
FLAGGEMS_VENDOR=arm uv pip install --no-build-isolation --editable "$WORK_DIR/FlagGems"
pins_check
uv pip freeze > "$WORK_DIR/logs/python-packages.txt"
