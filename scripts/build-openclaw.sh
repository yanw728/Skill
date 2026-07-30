#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

OUT_ROOT="$REPO_ROOT/dist/openclaw"
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

  if [[ -n "$overlay_dir" && -f "$overlay_dir/adapters/openclaw.yaml" ]]; then
    write_yaml_block "$overlay_dir/adapters/openclaw.yaml" > "$out_dir/SKILL.md"
  elif frontmatter_present "$source_dir/SKILL.md"; then
    extract_frontmatter "$source_dir/SKILL.md" > "$out_dir/SKILL.md"
  else
    printf -- "---\nname: %s\n---\n" "$skill" > "$out_dir/SKILL.md"
  fi

  printf '\n' >> "$out_dir/SKILL.md"
  strip_frontmatter "$source_dir/SKILL.md" >> "$out_dir/SKILL.md"

  if [[ -n "$overlay_dir" && -f "$overlay_dir/adapters/openclaw.md" ]]; then
    printf '\n\n***\n\n' >> "$out_dir/SKILL.md"
    cat "$overlay_dir/adapters/openclaw.md" >> "$out_dir/SKILL.md"
  fi

  copy_meta_if_present "$overlay_dir" "$out_dir"
  log "built openclaw/$skill"
done < <(list_skill_names)
