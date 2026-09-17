#!/usr/bin/env bash
set -euo pipefail
test "$(uname -s)" = Linux && test "$(uname -m)" = aarch64 || fail 'Linux aarch64 is required'
source /etc/os-release
test "$ID" = debian && test "$VERSION_ID" = 13 || fail 'setup targets Debian 13; install dependencies manually on other distributions'
if [ "${SKIP_SYSTEM_PACKAGES:-0}" != 1 ]; then
  APT=(apt-get)
  if [ "$EUID" -ne 0 ]; then
    command -v sudo >/dev/null || fail 'sudo is required for system packages; ask the administrator to install prerequisites'
    APT=(sudo apt-get)
  fi
  "${APT[@]}" update
  "${APT[@]}" install -y git curl ca-certificates procps util-linux build-essential \
    ccache ninja-build cmake gcc-12 g++-12 zlib1g-dev libxml2-dev \
    libnuma-dev libtcmalloc-minimal4t64 pipx
fi
host_check
export PATH="$HOME/.local/bin:$PATH"
uv() {
  if [ -x "$HOME/.local/bin/uv" ] && [ "$("$HOME/.local/bin/uv" --version)" = 'uv 0.8.24' ]; then
    "$HOME/.local/bin/uv" "$@"
  else
    command pipx run --spec 'uv==0.8.24' uv "$@"
  fi
}
uv python install 3.11.13
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
if [ ! -x "$PYTHON" ]; then uv venv --python 3.11.13 .venv; fi
source "$WORK_DIR/.venv/bin/activate"
fetch_commit https://github.com/vllm-project/vllm.git vllm "$VLLM_SHA"
fetch_commit https://github.com/flagos-ai/flagtree-cpu.git flagtree-cpu "$TREE_SHA"
fetch_commit https://github.com/flagos-ai/FlagGems.git FlagGems "$GEMS_SHA"
fetch_commit https://github.com/flagos-ai/vllm-plugin-FL.git vllm-plugin-FL "$PLUGIN_SHA"
for repo in vllm flagtree-cpu FlagGems vllm-plugin-FL; do
  git -C "$WORK_DIR/$repo" diff --exit-code
  git -C "$WORK_DIR/$repo" diff --cached --exit-code
done
git -C "$WORK_DIR/flagtree-cpu" submodule update --init --recursive
test "$(cat "$WORK_DIR/flagtree-cpu/cmake/llvm-hash.txt")" = "$LLVM_SHA"
test "$(git -C "$WORK_DIR/flagtree-cpu/third_party/sleef" rev-parse HEAD)" = "$SLEEF_SHA"
source "$SCRIPT_DIR/install.sh"
cd "$WORK_DIR/vllm-plugin-FL"
"$PYTHON" "$SCRIPT_DIR/verify_platform.py"
for repo in vllm flagtree-cpu FlagGems vllm-plugin-FL acl-v52.6.0 onednn-9c5be1; do
  printf '%s ' "$repo"
  git -C "$WORK_DIR/$repo" rev-parse HEAD
done > "$WORK_DIR/logs/source-revisions.txt"
uv pip freeze > "$WORK_DIR/logs/python-packages.txt"
