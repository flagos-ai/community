#!/usr/bin/env bash
set -euo pipefail
cp "$SCRIPT_DIR/requirements.lock" "$WORK_DIR/constraints.txt"
uv pip install -r "$WORK_DIR/vllm/requirements/cpu.txt" \
  --constraint "$WORK_DIR/constraints.txt" --index-strategy unsafe-best-match
uv pip install 'cmake==4.4.2' 'ninja==1.13.0' 'pybind11==3.0.3' \
  'setuptools==77.0.3' 'setuptools-scm==9.2.0' \
  'setuptools-rust==1.13.0' 'scikit-build-core==0.12.2' \
  pytest --constraint "$WORK_DIR/constraints.txt"

fetch_cpu_build_dependency() {
  repo_dir=$1
  repo_url=$2
  fetch_ref=$3
  source_sha=$4
  if [ ! -d "$WORK_DIR/$repo_dir/.git" ]; then
    git init -q "$WORK_DIR/$repo_dir"
  fi
  if ! git -C "$WORK_DIR/$repo_dir" remote get-url origin >/dev/null 2>&1; then
    git -C "$WORK_DIR/$repo_dir" remote add origin "$repo_url"
  fi
  test "$(git -C "$WORK_DIR/$repo_dir" remote get-url origin)" = "$repo_url"
  git -C "$WORK_DIR/$repo_dir" fetch --depth 1 origin "$fetch_ref"
  git -C "$WORK_DIR/$repo_dir" checkout --detach "$source_sha"
  test "$(git -C "$WORK_DIR/$repo_dir" rev-parse HEAD)" = "$source_sha"
}
fetch_cpu_build_dependency acl-v52.6.0 \
  https://github.com/ARM-software/ComputeLibrary.git refs/tags/v52.6.0 \
  007264fa740de5723ebddef16b7bb3657692c088
fetch_cpu_build_dependency onednn-9c5be1 \
  https://github.com/oneapi-src/oneDNN.git \
  9c5be1cc59e368aebf0909e6cf20f981ea61462a \
  9c5be1cc59e368aebf0909e6cf20f981ea61462a

export BUILD_JOBS="${BUILD_JOBS:-4}"
TRITON_HOME="$WORK_DIR/.triton-build" TRITON_BUILD_PROTON=OFF MAX_JOBS="$BUILD_JOBS" \
  uv pip install --no-build-isolation --constraint "$WORK_DIR/constraints.txt" \
  --editable "$WORK_DIR/flagtree-cpu"
if [ -f "$WORK_DIR/acl-v52.6.0/build/CMakeCache.txt" ]; then
  acl_source=$(realpath "$WORK_DIR/acl-v52.6.0")
  if ! grep -Fxq "CMAKE_HOME_DIRECTORY:INTERNAL=$acl_source" "$acl_source/build/CMakeCache.txt"; then
    fail 'ACL CMake cache belongs to another source path. Use a clean WORK_DIR; do not copy native build directories between paths.'
  fi
fi
cmake -G Ninja -S "$WORK_DIR/acl-v52.6.0" -B "$WORK_DIR/acl-v52.6.0/build" \
  -DARM_COMPUTE_BUILD_SHARED_LIB=OFF -DCMAKE_BUILD_TYPE=Release \
  -DARM_COMPUTE_ARCH=armv8.2-a -DARM_COMPUTE_ENABLE_ASSERTS=OFF \
  -DARM_COMPUTE_ENABLE_CPPTHREADS=OFF -DARM_COMPUTE_ENABLE_OPENMP=ON \
  -DARM_COMPUTE_ENABLE_WERROR=OFF -DARM_COMPUTE_BUILD_EXAMPLES=OFF \
  -DARM_COMPUTE_BUILD_TESTING=OFF
cmake --build "$WORK_DIR/acl-v52.6.0/build" --parallel "$BUILD_JOBS"
CMAKE_ARGS="-DFETCHCONTENT_SOURCE_DIR_ONEDNN=$WORK_DIR/onednn-9c5be1" \
ACL_ROOT_DIR="$WORK_DIR/acl-v52.6.0" \
VLLM_TARGET_DEVICE=cpu VLLM_VERSION_OVERRIDE=0.24.0+cpu MAX_JOBS="$BUILD_JOBS" \
  uv pip install --no-build-isolation --constraint "$WORK_DIR/constraints.txt" \
  --editable "$WORK_DIR/vllm"
unset VLLM_VENDOR
FLAGGEMS_VENDOR=arm uv pip install --no-build-isolation \
  --constraint "$WORK_DIR/constraints.txt" --editable "$WORK_DIR/FlagGems"
uv pip install --no-build-isolation --constraint "$WORK_DIR/constraints.txt" \
  --editable "$WORK_DIR/vllm-plugin-FL"
