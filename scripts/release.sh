#!/usr/bin/env bash
# release.sh — 一键更新版本、复制镜像、构建 LPK、可选发布
#
# 用法:
#   scripts/release.sh <version>                    # 仅更新+构建
#   scripts/release.sh <version> --publish          # 更新+构建+发布
#   scripts/release.sh <version> --publish --changelog '修复了xxx'  # 自定义 changelog
#
# 示例:
#   scripts/release.sh 4.2.2                        # 更新到 4.2.2，只构建
#   scripts/release.sh 4.2.2 --publish              # 更新到 4.2.2，构建并发布
#   scripts/release.sh 4.2.2 --skip-copy            # 跳过镜像复制（使用 --source-image）
#   scripts/release.sh 4.2.2 --source-image openlistteam/openlist:v4.2.2-aio  # 指定源镜像
#
# 本脚本基于 lazycat-app-publisher skill 的 lzc-release-update.sh
# 首次会记录 service 和 source_template 到 .lazycat-release.env，后续只需传版本号

set -euo pipefail
cd "$(dirname "$0")/.."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SCRIPT="$HOME/.claude/skills/lazycat-app-publisher/scripts/lzc-release-update.sh"

# ─── 检查依赖 ───
if [[ ! -f "$SKILL_SCRIPT" ]]; then
  echo "error: lazycat-app-publisher skill script not found at $SKILL_SCRIPT" >&2
  echo "  请确认 skill 已安装: ls ~/.claude/skills/lazycat-app-publisher/scripts/" >&2
  exit 1
fi

command -v lzc-cli >/dev/null 2>&1 || {
  echo "error: lzc-cli 未安装" >&2
  echo "  安装: npm install -g @lazycatcloud/lzc-cli@2.0.0" >&2
  exit 1
}

# ─── 默认参数 ───
# OpenList 只有一个镜像 service: openlist，源镜像模板
SERVICE="openlist"
SOURCE_TEMPLATE="openlistteam/openlist:v{version}-aio"

# ─── 参数处理 ───
if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  cat <<'HELP'
Usage: scripts/release.sh <version> [options]

一键更新版本、复制镜像、构建 LPK、可选发布到懒猫应用商店

Options (透传给 lzc-release-update.sh):
  --publish                    构建后发布到应用商店
  --changelog <text>           发布 changelog（默认: 更新到 <version>）
  --lang <lang>                Changelog 语言（默认: zh）
  --source-image <image>       指定完整源镜像
  --source-template <template> 指定源镜像模板
  --skip-copy                  跳过镜像复制
  --skip-build                 跳过 LPK 构建
  --no-remember                不保存配置到 .lazycat-release.env

Examples:
  scripts/release.sh 4.2.2                                   # 更新+构建
  scripts/release.sh 4.2.2 --publish                          # 更新+构建+发布
  scripts/release.sh 4.2.2 --source-image openlistteam/openlist:v4.2.2-aio
HELP
  exit 0
fi

VERSION="$1"
shift

# ─── 构建参数列表 ───
ARGS=(
  --service "$SERVICE"
  --source-template "$SOURCE_TEMPLATE"
)

# 透传剩余参数
for arg in "$@"; do
  ARGS+=("$arg")
done

# ─── 执行 ───
echo "╔══════════════════════════════════════════════╗"
echo "║     OpenList LazyCat Release Helper          ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Version:  $VERSION"
echo "║  Service:  $SERVICE"
echo "║  Template: $SOURCE_TEMPLATE"
echo "╚══════════════════════════════════════════════╝"
echo ""

bash "$SKILL_SCRIPT" "$VERSION" "${ARGS[@]}"

echo ""
echo "✅ Release 完成! 版本 $VERSION 已就绪。"
echo ""
echo "下一步:"
echo "  scripts/git-push.sh $VERSION          # 提交并推送到 GitHub"
echo "  scripts/release.sh $VERSION --publish # 发布到应用商店"
echo ""
