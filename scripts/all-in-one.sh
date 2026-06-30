#!/usr/bin/env bash
# all-in-one.sh — 一键完成全部流程: 更新版本 → 构建LPK → 发布商店 → Git提交推送
#
# 用法:
#   scripts/all-in-one.sh <version>               # 更新+构建+Git推送（不发布商店）
#   scripts/all-in-one.sh <version> --publish      # 全流程: 更新+构建+发布+推送
#   scripts/all-in-one.sh <version> --publish --changelog '修复了xxx'
#
# 示例:
#   scripts/all-in-one.sh 4.2.2                   # 仅更新构建+推送
#   scripts/all-in-one.sh 4.2.2 --publish          # 含发布到商店
#
# 本脚本串联 release.sh 和 git-push.sh，中途失败会停止。
# 发布到商店是显式动作，只有加 --publish 才会执行。

set -euo pipefail
cd "$(dirname "$0")/.."

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── 参数处理 ───
if [[ $# -lt 1 ]]; then
  cat <<'HELP'
Usage: scripts/all-in-one.sh <version> [options]

一键完成: 更新版本 → 复制镜像 → 构建LPK → (可选)发布商店 → Git提交推送

Options:
  --publish              构建后发布到懒猫应用商店
  --changelog <text>     发布 changelog（默认: 更新到 <version>）
  --lang <lang>          Changelog 语言（默认: zh）
  --source-image <url>   指定源镜像（跳过自动推导）
  --skip-copy            跳过镜像复制
  --skip-build           跳过 LPK 构建
  --dry-run              只显示将执行的命令，不实际推送 git
  -m <message>           自定义 git commit 信息（默认: bump <version>）
  -h, --help             显示帮助

Examples:
  scripts/all-in-one.sh 4.2.2                     # 更新+构建+推送，不发布
  scripts/all-in-one.sh 4.2.2 --publish           # 全流程含发布
  scripts/all-in-one.sh 4.2.2 -m "升级到 4.2.2"   # 自定义 commit 信息
HELP
  exit 1
fi

VERSION="$1"
shift

# 分离参数给 release 和 git
RELEASE_ARGS=()
GIT_ARGS=()
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --publish|--changelog|--lang|--source-image|--source-template|--skip-copy|--skip-build|--no-remember)
      RELEASE_ARGS+=("$1")
      if [[ "$1" == --changelog || "$1" == --lang || "$1" == --source-image || "$1" == --source-template ]]; then
        RELEASE_ARGS+=("${2:-}")
        shift
      fi
      shift
      ;;
    -m|--message)
      GIT_ARGS+=("-m" "${2:-}")
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      GIT_ARGS+=("--dry-run")
      shift
      ;;
    -h|--help)
      scripts/all-in-one.sh --help 2>/dev/null || true
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 1
      ;;
  esac
done

echo "╔══════════════════════════════════════════════════╗"
echo "║     OpenList All-in-One Release Helper           ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  Version:    $VERSION"
echo "║  Publish:    $(printf '%s\n' "${RELEASE_ARGS[@]}" | grep -q publish && echo 'Yes ✅' || echo 'No (add --publish)')"
echo "║  Git push:   $(printf '%s\n' "${GIT_ARGS[@]}" | grep -q dry-run && echo 'Dry-run' || echo 'Yes ✅')"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─── 阶段1: 版本更新 + 镜像复制 + 构建 ───
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  阶段 1/2: 更新版本 & 构建 LPK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPTS_DIR/release.sh" "$VERSION" "${RELEASE_ARGS[@]:-}"

# ─── 阶段2: Git 提交 & 推送 ───
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  阶段 2/2: Git 提交 & 推送"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPTS_DIR/git-push.sh" "$VERSION" "${GIT_ARGS[@]:-}"

echo ""
echo "══════════════════════════════════════════════════"
echo "  🎉 All-in-one 完成! 版本 $VERSION 全流程结束。"
echo "══════════════════════════════════════════════════"
