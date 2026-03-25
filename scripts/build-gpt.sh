#!/usr/bin/env bash
# build-gpt.sh — 组装 GPT 版本的 Skill 文件
#
# 做什么：
#   如果有 adapters/gpt.md，直接用它（因为 GPT 通常需要精简版）。
#   如果没有，复制原始 SKILL.md 并去掉 YAML frontmatter。
#   输出到 dist/gpt/ 目录。
#
# 注意：GPT Custom Instructions 有字符数限制，建议在 adapters/gpt.md
# 里写一个精简版本，只保留最关键的规则。
#
# 用法：
#   bash scripts/build-gpt.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIRS=("$REPO_ROOT/skills/my" "$REPO_ROOT/skills/vendor")
OUT_DIR="$REPO_ROOT/dist/gpt"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

count=0

for src_dir in "${SRC_DIRS[@]}"; do
  [ -d "$src_dir" ] || continue

  for skill_dir in "$src_dir"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue

    skill_name="$(basename "$skill_dir")"

    if [ -f "$skill_dir/adapters/gpt.md" ]; then
      # 有精简版，直接使用
      cp "$skill_dir/adapters/gpt.md" "$OUT_DIR/${skill_name}.md"
    else
      # 没有精简版，去掉 frontmatter 后复制
      awk '
        BEGIN { in_front=0; front_done=0 }
        /^---$/ && !front_done { in_front++; if(in_front==2) { front_done=1 }; next }
        front_done || !in_front { print }
      ' "$skill_dir/SKILL.md" > "$OUT_DIR/${skill_name}.md"
    fi

    count=$((count + 1))
    echo "  ✓ $skill_name"
  done
done

echo ""
echo "GPT 构建完成：$count 个 skill → $OUT_DIR"
echo "提示：GPT Custom Instructions 有字符数限制，请检查每个文件的长度。"
