#!/usr/bin/env bash
set -euo pipefail
download_blob() {
  local expected=$1 name=$2 url=$3
  if (cd "$SOURCE_MODEL" && printf '%s  %s\n' "$expected" "$name" | sha256sum -c - >/dev/null 2>&1); then
    echo "$name already verified"
    return
  fi
  if [ -f "$SOURCE_MODEL/$name" ] && head -c 64 "$SOURCE_MODEL/$name" | grep -q '^version https://git-lfs.github.com/spec/v1'; then
    truncate -s 0 "$SOURCE_MODEL/$name"
  fi
  curl --fail --location --retry 3 --continue-at - --output "$SOURCE_MODEL/$name" "$url"
  (cd "$SOURCE_MODEL" && printf '%s  %s\n' "$expected" "$name" | sha256sum -c -)
}
download_model() {
  local kind=$1 revision repo weight_sha
  case "$kind" in
    w4) SOURCE_MODEL="$W4_SOURCE"; revision=$W4_REV; weight_sha=$W4_WEIGHT_SHA; repo=MiniCPM5-2B-W4A8-arm-FlagOS ;;
    w8) SOURCE_MODEL="$W8_MODEL"; revision=$W8_REV; weight_sha=$W8_WEIGHT_SHA; repo=MiniCPM5-2B-W8A8-arm-FlagOS ;;
    *) fail 'models accepts w4, w8 or all' ;;
  esac
  local git_url="https://www.modelscope.cn/FlagRelease/$repo.git"
  mkdir -p "$SOURCE_MODEL"
  if [ ! -e "$SOURCE_MODEL/.git" ]; then git init -q "$SOURCE_MODEL"; fi
  if ! git -C "$SOURCE_MODEL" remote get-url origin >/dev/null 2>&1; then
    git -C "$SOURCE_MODEL" remote add origin "$git_url"
  fi
  test "$(git -C "$SOURCE_MODEL" remote get-url origin)" = "$git_url"
  if [ "$(git -C "$SOURCE_MODEL" rev-parse HEAD 2>/dev/null || true)" != "$revision" ]; then
    GIT_LFS_SKIP_SMUDGE=1 git -C "$SOURCE_MODEL" fetch --depth 1 origin "$revision"
    GIT_LFS_SKIP_SMUDGE=1 git -C "$SOURCE_MODEL" checkout --detach "$revision"
  fi
  local resolve="https://www.modelscope.cn/models/FlagRelease/$repo/resolve/$revision"
  download_blob "$weight_sha" model-00000-of-00001.safetensors "$resolve/model-00000-of-00001.safetensors"
  download_blob "$TOKENIZER_SHA" tokenizer.json "$resolve/tokenizer.json"
  test "$(git -C "$SOURCE_MODEL" rev-parse HEAD)" = "$revision"
  if [ "$kind" = w4 ]; then "$PYTHON" "$SCRIPT_DIR/pack_w4.py"; fi
  model_kind "$kind"
  "$PYTHON" "$SCRIPT_DIR/verify_model.py"
}
case "${1:-all}" in
  all) download_model w4; download_model w8 ;;
  w4|w8) download_model "$1" ;;
  *) fail 'models accepts w4, w8 or all' ;;
esac
