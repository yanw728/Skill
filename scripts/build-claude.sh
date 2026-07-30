#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OUT_ROOT="$REPO_ROOT/dist/claude"
clean_dist_dir "$OUT_ROOT"

while IFS= read -r skill; do
  [[ -n "$skill" ]] || continue

  source_dir="$(resolve_source_dir "$skill" || true)"
  overlay_dir="$(resolve_overlay_dir "$skill" || true)"

  if [[ -z "$source_dir" ]]; then
    log "skip $skill: no source SKILL.md found"
    continue
  fi

  out_dir="$OUT_ROOT/$skill"
  mkdir -p "$out_dir"

  strip_frontmatter "$source_dir/SKILL.md" > "$out_dir/SKILL.md"

  if [[ -n "$overlay_dir" && -f "$overlay_dir/adapters/claude.md" ]]; then
    printf '\n\n***\n\n' >> "$out_dir/SKILL.md"
    cat "$overlay_dir/adapters/claude.md" >> "$out_dir/SKILL.md"
  fi

  description="$(
    if [[ -n "$overlay_dir" && -f "$overlay_dir/meta.yaml" ]]; then
      extract_yaml_description "$overlay_dir/meta.yaml"
    else
      extract_yaml_description "$source_dir/SKILL.md"
    fi
  )"

  if [[ -n "$description" ]]; then
    printf '%s\n' "$description" > "$out_dir/description.txt"
  fi

  copy_meta_if_present "$overlay_dir" "$out_dir"
  log "built claude/$skill"
done < <(list_skill_names)
