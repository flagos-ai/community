#!/usr/bin/env python3
"""
FlagOS Release Branch & Tag Manager

从 release-*.yaml 中读取模块清单，自动化：
  1. 为每个模块创建对应的 release 分支（基于默认分支）
  2. 在分支上打上 version 指定的 tag
  3. 推送分支 + tag 到 origin

用法:
  # 预览模式（不实际操作）
  python manage-release.py --dry-run release-2.1-rc0.yaml

  # 执行操作
  python manage-release.py release-2.1-rc0.yaml

  # 指定工作目录（默认 /tmp/flagos-release）
  python manage-release.py --workdir /path/to/workspace release-2.1-rc2.yaml

依赖: Python 3.8+, PyYAML, git CLI
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


def parse_manifest(filepath):
    """Parse a release YAML manifest, extracting repo name, url, version tag, and branch.

    Returns a list of dicts with keys: name, url, version, branch, default_branch
    """
    repos = []
    with open(filepath) as f:
        lines = f.readlines()

    current_repo = None
    for i, line in enumerate(lines):
        # Match top-level repo key (indented 2 spaces, ends with colon)
        repo_match = re.match(r"^  (\S+):\s*$", line)
        if repo_match:
            name = repo_match.group(1)
            # Scan forward for url, version, and branch comment
            url = version = branch = None
            default_branch = "main"
            for j in range(i + 1, min(i + 30, len(lines))):
                l = lines[j]
                # Stop at next top-level key
                if re.match(r"^  \S+:\s*$", l) and not l.startswith("    "):
                    break
                if "url:" in l and url is None:
                    url = re.search(r"url:\s*(\S+)", l).group(1)
                if "version:" in l and version is None:
                    version = re.search(r"version:\s*(\S+)", l).group(1)
                if "分支:" in l and branch is None:
                    branch = re.search(r"分支:\s*(\S+)", l).group(1)
                if "默认分支: master" in l:
                    default_branch = "master"

            if url and version and branch:
                repos.append({
                    "name": name,
                    "url": url,
                    "version": version,
                    "branch": branch,
                    "default_branch": default_branch,
                })
            else:
                print(f"⚠ 跳过 {name}: url={url}, version={version}, branch={branch}")

    return repos


def run(cmd, cwd=None, check=True):
    """Run a shell command, return stdout."""
    result = subprocess.run(
        cmd, shell=True, cwd=cwd, capture_output=True, text=True
    )
    if check and result.returncode != 0:
        print(f"  ✗ 命令失败: {cmd}")
        print(f"    stderr: {result.stderr.strip()}")
        sys.exit(1)
    return result.stdout.strip(), result.returncode


def process_repo(repo, workdir, dry_run=False):
    """Clone, create branch, and tag a single repo."""
    name = repo["name"]
    url = repo["url"]
    version = repo["version"]
    branch = repo["branch"]
    default_branch = repo["default_branch"]
    repodir = os.path.join(workdir, name)

    print(f"\n{'='*60}")
    print(f"📦 {name}")
    print(f"   分支: {branch}  |  tag: {version}  |  默认分支: {default_branch}")
    print(f"{'='*60}")

    # --- Clone ---
    if os.path.isdir(repodir):
        print(f"  📂 仓库已存在，fetch 最新...")
        if not dry_run:
            run("git fetch --all --prune", cwd=repodir)
            run(f"git checkout {default_branch}", cwd=repodir)
            run(f"git pull origin {default_branch}", cwd=repodir)
    else:
        print(f"  ⬇ clone {url}")
        if not dry_run:
            os.makedirs(workdir, exist_ok=True)
            run(f"git clone {url} {repodir}")

    # --- Create branch ---
    branch_exists = False
    if not dry_run:
        out, _ = run(f"git branch -r", cwd=repodir, check=False)
        branch_exists = any(f"origin/{branch}" in line for line in out.splitlines())

    if branch_exists:
        print(f"  ∟ 远程分支 origin/{branch} 已存在，跳过创建")
    else:
        print(f"  🌿 创建分支 {branch} (基于 {default_branch})")
        if not dry_run:
            run(f"git checkout -b {branch} origin/{default_branch}", cwd=repodir)
            run(f"git push origin {branch}", cwd=repodir)
            print(f"  ✓ 分支 {branch} 已推送")

    # --- Create tag ---
    tag_exists = False
    if not dry_run:
        out, _ = run(f"git tag -l", cwd=repodir, check=False)
        tag_exists = version in out.splitlines()

    if tag_exists:
        print(f"  ∟ tag {version} 已存在，跳过创建")
    else:
        print(f"  🏷  打 tag {version} (基于分支 {branch})")
        if not dry_run:
            run(f"git checkout {branch}", cwd=repodir)
            run(f"git pull origin {branch}", cwd=repodir)
            run(f"git tag -a {version} -m 'FlagOS 2.1 release: {version}'", cwd=repodir)
            run(f"git push origin {version}", cwd=repodir)
            print(f"  ✓ tag {version} 已推送")


def main():
    parser = argparse.ArgumentParser(
        description="FlagOS Release — 自动化分支创建 & 打 Tag 工具"
    )
    parser.add_argument("manifest", help="release YAML 文件路径")
    parser.add_argument(
        "--dry-run", action="store_true", help="预览模式，不实际操作"
    )
    parser.add_argument(
        "--workdir",
        default="/tmp/flagos-release",
        help="工作目录，用于 clone 各仓库 (默认: /tmp/flagos-release)",
    )
    parser.add_argument(
        "--filter",
        help="只处理名称匹配的模块 (支持部分匹配)",
    )
    args = parser.parse_args()

    repos = parse_manifest(args.manifest)
    print(f"📋 从 {args.manifest} 解析到 {len(repos)} 个模块")

    if args.dry_run:
        print("🔍 DRY-RUN 模式：仅预览，不实际操作\n")

    filtered = [r for r in repos if not args.filter or args.filter in r["name"]]
    if args.filter:
        print(f"🔎 过滤条件: '{args.filter}' → 匹配 {len(filtered)} 个模块\n")

    success = 0
    skipped = 0
    for repo in filtered:
        try:
            process_repo(repo, args.workdir, dry_run=args.dry_run)
            success += 1
        except Exception as e:
            print(f"  ✗ 失败: {e}")
            skipped += 1

    print(f"\n{'='*60}")
    print(f"✅ 完成: {success} 成功, {skipped} 跳过/失败")
    if args.dry_run:
        print(f"🔍 以上为预览，使用去掉 --dry-run 执行实际操作")


if __name__ == "__main__":
    main()
