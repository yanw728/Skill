#!/usr/bin/env bash
# build-openclaw.sh — 组装 OpenClaw 版本的 Skill 文件
#
# 做什么：
#   读取每个 skill 的 SKILL.md，如果有 adapters/openclaw.yaml 就把它的
#   YAML frontmatter 插入到 SKILL.md 顶部，输出到 dist/openclaw/ 目录。
#
# 用法：
#   bash scripts/build-openclaw.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIRS=("$REPO_ROOT/skills/my" "$REPO_ROOT/skills/vendor")
OUT_DIR="$REPO_ROOT/dist/openclaw"

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

    # 如果有 OpenClaw 适配文件，用它的 frontmatter 替换原有的
    if [ -f "$skill_dir/adapters/openclaw.yaml" ]; then
      # 构建新文件：openclaw frontmatter + 原始正文（去掉原 frontmatter）
      {
        echo "---"
        cat "$skill_dir/adapters/openclaw.yaml"
        echo "---"
        echo ""
        # 去掉原文件的 frontmatter（如果有的话），保留正文
        awk '
          BEGIN { in_front=0; front_done=0 }
          /^---$/ && !front_done { in_front++; if(in_front==2) { front_done=1 }; next }
          front_done || !in_front { print }
        ' "$skill_dir/SKILL.md"
      } > "$out_skill_dir/SKILL.md"
    else
      # 没有适配文件，直接复制
      cp "$skill_dir/SKILL.md" "$out_skill_dir/SKILL.md"
    fi

    # 复制 references/
    if [ -d "$skill_dir/references" ]; then
      cp -r "$skill_dir/references" "$out_skill_dir/references"
    fi

    count=$((count + 1))
    echo "  ✓ $skill_name"
  done
done

echo ""
echo "OpenClaw 构建完成：$count 个 skill → $OUT_DIR"
