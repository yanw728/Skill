#!/usr/bin/env bash
# sync-vendor.sh — 从 GitHub 或 ClawHub 同步第三方 Skill
#
# 做什么：
#   扫描 skills/vendor/ 下每个 skill 的 meta.yaml，
#   根据 source 字段拉取最新版本。
#
# 支持的来源：
#   - GitHub URL：git clone / git pull
#   - clawhub://skill-name：需要安装 clawhub CLI
#
# 用法：
#   bash scripts/sync-vendor.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$REPO_ROOT/skills/vendor"

if [ ! -d "$VENDOR_DIR" ] || [ -z "$(ls -A "$VENDOR_DIR" 2>/dev/null)" ]; then
  echo "没有找到第三方 skill。"
  echo ""
  echo "如何添加："
  echo "  1. 在 skills/vendor/ 下新建文件夹，命名为 {作者}--{skill 名称}"
  echo "  2. 把原始 SKILL.md 放进去"
  echo "  3. 创建 meta.yaml 填写 source 字段（GitHub URL 或 clawhub://name）"
  echo "  4. 再次运行本脚本即可自动同步"
  exit 0
fi

synced=0
failed=0

for skill_dir in "$VENDOR_DIR"/*/; do
  [ -f "$skill_dir/meta.yaml" ] || continue

  skill_name="$(basename "$skill_dir")"
  source="$(grep '^source:' "$skill_dir/meta.yaml" | sed 's/^source:[[:space:]]*//')"

  if [ -z "$source" ] || [ "$source" = "local" ]; then
    echo "  ⏭ $skill_name（本地，跳过）"
    continue
  fi

  echo "  ↻ 同步 $skill_name ← $source"

  if [[ "$source" == https://github.com/* ]]; then
    # GitHub 来源
    temp_dir=$(mktemp -d)
    if git clone --depth 1 "$source" "$temp_dir" 2>/dev/null; then
      # 只复制 SKILL.md 和 references/
      [ -f "$temp_dir/SKILL.md" ] && cp "$temp_dir/SKILL.md" "$skill_dir/SKILL.md"
      [ -d "$temp_dir/references" ] && cp -r "$temp_dir/references" "$skill_dir/"
      # 更新同步日期
      sed -i "s/^last_synced:.*/last_synced: $(date +%Y-%m-%d)/" "$skill_dir/meta.yaml"
      echo "    ✓ 完成"
      synced=$((synced + 1))
    else
      echo "    ✗ 克隆失败"
      failed=$((failed + 1))
    fi
    rm -rf "$temp_dir"

  elif [[ "$source" == clawhub://* ]]; then
    claw_name="${source#clawhub://}"
    if command -v clawhub &>/dev/null; then
      clawhub install "$claw_name" --target "$skill_dir" 2>/dev/null && {
        sed -i "s/^last_synced:.*/last_synced: $(date +%Y-%m-%d)/" "$skill_dir/meta.yaml"
        echo "    ✓ 完成"
        synced=$((synced + 1))
      } || {
        echo "    ✗ 安装失败"
        failed=$((failed + 1))
      }
    else
      echo "    ✗ 未安装 clawhub CLI（npm install -g clawhub）"
      failed=$((failed + 1))
    fi

  else
    echo "    ✗ 不支持的来源格式：$source"
    failed=$((failed + 1))
  fi
done

echo ""
echo "同步完成：成功 $synced，失败 $failed"
