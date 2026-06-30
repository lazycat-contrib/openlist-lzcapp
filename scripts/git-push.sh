#!/usr/bin/env bash
# git-push.sh — 一键提交并推送配置到 GitHub
#
# 用法:
#   scripts/git-push.sh <version>                 # 默认提交信息: bump <version>
#   scripts/git-push.sh <version> -m "修复了xxx"  # 自定义提交信息
#   scripts/git-push.sh <version> --dry-run        # 只显示将要执行的 git 命令，不实际执行
#
# 本脚本只提交 .yml / .md / .png / .gitignore / scripts/ 等配置文件，
# 不会提交 .lpk 构建产物。

set -euo pipefail
cd "$(dirname "$0")/.."

# ─── 参数处理 ───
if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/git-push.sh <version> [-m <message>] [--dry-run]" >&2
  exit 1
fi

VERSION="$1"
shift

MESSAGE="bump $VERSION"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--message)
      MESSAGE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ─── 检查 git 状态 ───
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null || [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]]; then
  : # 有变更，继续
else
  echo "ℹ️  没有检测到任何变更，无需提交。"
  exit 0
fi

# ─── 列出将要提交的文件 ───
echo "╔══════════════════════════════════════════════╗"
echo "║     OpenList Git Push Helper                 ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Version:  $VERSION"
echo "║  Message:  $MESSAGE"
echo "╚══════════════════════════════════════════════╝"
echo ""

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "  [dry-run] $*"
  else
    echo "  $ $*"
    "$@"
  fi
}

# ─── git add: 只添加配置文件，排除 .lpk ───
echo "📦 添加配置文件..."
run git add \
  package.yml \
  lzc-manifest.yml \
  lzc-build.yml \
  lzc-deploy-params.yml \
  icon.png \
  README.md \
  .gitignore \
  scripts/ \
  2>/dev/null || true

# 也添加其他可能的新 yml 文件
run git add '*.yml' 2>/dev/null || true

# ─── 确认已暂存的变更 ───
echo ""
echo "📋 暂存区变更:"
if [[ "$DRY_RUN" == "0" ]]; then
  git diff --cached --stat || echo "  (无)"
else
  echo "  [dry-run] git diff --cached --stat"
fi
echo ""

# ─── commit ───
echo "📝 提交..."
run git commit -m "$MESSAGE"
echo ""

# ─── push ───
BRANCH=$(git branch --show-current)
echo "🚀 推送到 origin/$BRANCH..."
run git push origin "$BRANCH"
echo ""

echo "✅ Git 推送完成! 版本 $VERSION 已推送到 GitHub。"
