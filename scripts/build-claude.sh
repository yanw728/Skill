#!/usr/bin/env bash
# build-claude.sh — 组装 Claude 版本的 Skill 文件
#
# 做什么：
#   读取每个 skill 的 SKILL.md，如果有 adapters/claude.md 就追加合并，
#   最终输出到 dist/claude/ 目录。
#
# 用法：
#   bash scripts/build-claude.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIRS=("$REPO_ROOT/skills/my" "$REPO_ROOT/skills/vendor")
OUT_DIR="$REPO_ROOT/dist/claude"

# 清空输出目录
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

count=0

for src_dir in "${SRC_DIRS[@]}"; do
  [ -d "$src_dir" ] || continue

  for skill_dir in "$src_dir"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue

    skill_name="$(basename "$skill_dir")"
    out_skill_dir="$OUT_DIR/$skill_name"
    mkdir -p "$out_skill_dir"

    # 基础：复制 SKILL.md
    cp "$skill_dir/SKILL.md" "$out_skill_dir/SKILL.md"

    # 如果有 Claude 适配文件，追加到 SKILL.md 末尾
    if [ -f "$skill_dir/adapters/claude.md" ]; then
      printf '\n\n---\n\n' >> "$out_skill_dir/SKILL.md"
      cat "$skill_dir/adapters/claude.md" >> "$out_skill_dir/SKILL.md"
    fi

    # 复制 references/ 目录（如果有）
    if [ -d "$skill_dir/references" ]; then
      cp -r "$skill_dir/references" "$out_skill_dir/references"
    fi

    count=$((count + 1))
    echo "  ✓ $skill_name"
  done
done

echo ""
echo "Claude 构建完成：$count 个 skill → $OUT_DIR"
