#!/bin/bash
# =============================================================================
# FlagOS 2.1 RC0 — 批量创建 rc0 分支并打 rc0.1 tag
# =============================================================================
# 用法:
#   预览模式:      bash rc0-branch.sh --dry-run
#   执行（全部）:  bash rc0-branch.sh
#   只打 tag:      bash rc0-branch.sh --tag-only
#
# 前置条件:
#   1. 所有模块已克隆到 src/ 目录下（通过 vcs import src < 2.1/release-2.1-rc0.yaml）
#   2. 对每个模块有推送权限
#
# 流程:
#   1. 从默认分支 (main/master) HEAD 拉 rc0 分支
#   2. 推送 rc0 分支
#   3. 在 rc0 分支 HEAD 打 rc0.1 tag
#   4. 推送 tag
#
# 分支 / tag 命名规则:
#   - rc0 分支: 每个模块使用自己的版本号和命名规则
#   - rc0.1 tag: 在分支名后追加 .1
#   详见 RC0_BRANCH_PLAN.md
# =============================================================================

set -e

DRY_RUN=false
TAG_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=true; shift ;;
    --tag-only) TAG_ONLY=true; shift ;;
    *) shift ;;
  esac
done

# ---- 每个模块的 rc0 分支名 ----
declare -A RC0_BRANCH
RC0_BRANCH["flagscale"]="release/v1.1.0-rc0"
RC0_BRANCH["megatron-lm-fl"]="release/v0.2.0-rc0"
RC0_BRANCH["verl-fl"]="release/v0.2.0-rc0"
RC0_BRANCH["flagtree"]="v0.5.0-rc0"
RC0_BRANCH["flagcx"]="v0.13.0-rc0"
RC0_BRANCH["flaggems"]="v5.3.0-rc0"
RC0_BRANCH["flagsparse"]="v0.2-rc0"
RC0_BRANCH["flagdnn"]="v0.2-rc0"
RC0_BRANCH["flagblas"]="v0.2-rc0"
RC0_BRANCH["flagtensor"]="v0.2-rc0"
RC0_BRANCH["flagaudio"]="v0.2-rc0"
RC0_BRANCH["flagattention"]="v0.3-rc0"
RC0_BRANCH["vllm-plugin-fl"]="v0.2.0-rc0"
RC0_BRANCH["kernelgen"]="v2.1.0-rc0"
RC0_BRANCH["kernelgenbench"]="v0.1.0-rc0"
RC0_BRANCH["skills"]="v1.1.0-rc0"
RC0_BRANCH["sglang-plugin-fl"]="v0.1.0-rc0"
RC0_BRANCH["pytorch-plugin-fl"]="v0.1.0-rc0"
RC0_BRANCH["flagquantum"]="v0.1.0-rc0"
RC0_BRANCH["flagfft"]="v0.1.0-rc0"
RC0_BRANCH["flagrelease"]="v0.1.0-rc0"
RC0_BRANCH["flagos-robo"]="v0.1.0-rc0"
RC0_BRANCH["transformerengine-fl"]="release/v0.2.0-rc0"

# ---- 每个模块的默认分支 ----
declare -A DEFAULT_BRANCH
MODULES=(
  "flagtree" "flagcx" "flaggems" "flagfft" "flagsparse" "flagdnn" "flagblas"
  "flagtensor" "flagaudio" "flagattention" "pytorch-plugin-fl" "vllm-plugin-fl"
  "sglang-plugin-fl" "transformerengine-fl" "megatron-lm-fl" "verl-fl"
  "flagscale" "flagquantum" "flagos-robo" "kernelgen" "kernelgenbench" "flagrelease" "skills"
)
for m in "${MODULES[@]}"; do
  DEFAULT_BRANCH[$m]="main"
done
DEFAULT_BRANCH["flaggems"]="master"
DEFAULT_BRANCH["flagdnn"]="master"
DEFAULT_BRANCH["flagblas"]="master"

log()  { echo "[$(date '+%H:%M:%S')] $*"; }
err()  { echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2; }

tag_counter=0
branch_counter=0

for module in "${MODULES[@]}"; do
  defbr="${DEFAULT_BRANCH[$module]}"
  rc0br="${RC0_BRANCH[$module]}"
  rc0tag="${rc0br}.1"

  echo ""
  log "=== $module (branch: $rc0br, tag: $rc0tag) ==="

  if [ ! -d "src/$module/.git" ]; then
    err "$module: not found at src/$module, skipping"
    continue
  fi

  cd "src/$module"

  # ---- 切到默认分支 ----
  current_br=$(git branch --show-current)
  if [ "$current_br" != "$defbr" ]; then
    log "  switching from $current_br to $defbr"
    git checkout "$defbr" 2>/dev/null || {
      err "$module: cannot checkout $defbr"
      cd - > /dev/null
      continue
    }
  fi

  # ---- 拉取最新 ----
  has_remote=$(git remote | wc -l)
  if [ "$has_remote" -gt 0 ]; then
    git fetch origin 2>/dev/null || log "  (fetch skipped, no remote)"
  fi

  # =======================================================================
  # Phase 1: 创建 rc0 分支
  # =======================================================================
  if [ "$TAG_ONLY" != true ]; then
    if git branch -a | grep -q "$rc0br"; then
      log "  branch $rc0br already exists, skipping"
    else
      log "  creating branch $rc0br at $(git log --oneline -1 --format='%h %s')"
      if [ "$DRY_RUN" = true ]; then
        log "  [DRY RUN] would: git checkout -b $rc0br"
        log "  [DRY RUN] would: git push origin $rc0br"
      else
        git checkout -b "$rc0br"
        git push origin "$rc0br" 2>/dev/null || log "  (push skipped, no remote or no permission)"
      fi
      ((branch_counter++))
    fi
  fi

  # 确保在 rc0 分支上
  if [ "$current_br" != "$rc0br" ]; then
    git checkout "$rc0br" 2>/dev/null || {
      err "$module: cannot checkout $rc0br"
      cd - > /dev/null
      continue
    }
  fi

  # =======================================================================
  # Phase 2: 打 rc0.1 tag
  # =======================================================================
  if git tag -l | grep -q "^${rc0tag}$"; then
    log "  tag $rc0tag already exists, skipping"
  else
    log "  tagging $rc0tag at $(git log --oneline -1 --format='%h %s')"
    if [ "$DRY_RUN" = true ]; then
      log "  [DRY RUN] would: git tag -a $rc0tag -m 'FlagOS 2.1 RC0.1'"
      log "  [DRY RUN] would: git push origin $rc0tag"
    else
      git tag -a "$rc0tag" -m "FlagOS 2.1 RC0.1 — ${rc0br}"
      git push origin "$rc0tag" 2>/dev/null || log "  (tag push skipped, no remote or no permission)"
    fi
    ((tag_counter++))
  fi

  cd - > /dev/null
done

echo ""
log "=== Done ==="
if [ "$DRY_RUN" = true ]; then
  log "This was a dry run. Remove --dry-run to execute."
else
  log "Created ${branch_counter} branches, ${tag_counter} tags."
  log "Next: update release-2.1-rc0.yaml version fields to rc0.1 tags"
fi
