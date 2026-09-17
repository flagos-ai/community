fetch_commit() {
  repo_url=$1
  repo_dir=$2
  source_sha=$3
  if [ ! -e "$WORK_DIR/$repo_dir/.git" ]; then
    git init -q "$WORK_DIR/$repo_dir"
  fi
  if ! git -C "$WORK_DIR/$repo_dir" remote get-url origin >/dev/null 2>&1; then
    git -C "$WORK_DIR/$repo_dir" remote add origin "$repo_url"
  fi
  test "$(git -C "$WORK_DIR/$repo_dir" remote get-url origin)" = "$repo_url"
  git -C "$WORK_DIR/$repo_dir" diff --exit-code
  git -C "$WORK_DIR/$repo_dir" diff --cached --exit-code
  if [ "$(git -C "$WORK_DIR/$repo_dir" rev-parse HEAD 2>/dev/null || true)" = "$source_sha" ]; then
    return
  fi
  git -C "$WORK_DIR/$repo_dir" fetch --depth 1 origin "$source_sha"
  git -C "$WORK_DIR/$repo_dir" checkout --detach "$source_sha"
  test "$(git -C "$WORK_DIR/$repo_dir" rev-parse HEAD)" = "$source_sha"
}
