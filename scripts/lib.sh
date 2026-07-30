#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log() {
  printf '%s\n' "$*" >&2
}

die() {
  log "Error: $*"
  exit 1
}

clean_dist_dir() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
}

frontmatter_present() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  [[ "$(head -n 1 "$file")" == "---" ]]
}

extract_frontmatter() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_block = 1; print; next }
    in_block {
      print
      if ($0 == "---") {
        exit
      }
    }
  ' "$file"
}

strip_frontmatter() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_block = 1; next }
    in_block && $0 == "---" { in_block = 0; next }
    !in_block { print }
  ' "$file"
}

extract_yaml_description() {
  local file="$1"
  awk '
    BEGIN {
      capture = 0
      first = 1
    }
    NR == 1 && $0 == "---" { next }
    /^---$/ && !capture { next }
    /^description:[[:space:]]*>[[:space:]]*$/ {
      capture = 1
      next
    }
    /^description:[[:space:]]*[^[:space:]].*$/ {
      sub(/^description:[[:space:]]*/, "", $0)
      gsub(/^"/, "", $0)
      gsub(/"$/, "", $0)
      print
      exit
    }
    capture {
      if ($0 ~ /^[A-Za-z0-9_-]+:[[:space:]]*/ && $0 !~ /^[[:space:]]+/) {
        exit
      }
      gsub(/^[[:space:]]+/, "", $0)
      if (length($0) == 0) {
        next
      }
      if (!first) {
        printf " "
      }
      printf "%s", $0
      first = 0
    }
    END {
      if (!first) {
        printf "\n"
      }
    }
  ' "$file"
}

list_legacy_skill_dirs() {
  find "$REPO_ROOT" -mindepth 1 -maxdepth 1 -type d \
    ! -name ".git" \
    ! -name "dist" \
    ! -name "scripts" \
    ! -name "skills" \
    ! -name "templates" \
    -print0 |
    while IFS= read -r -d '' dir; do
      if [[ -f "$dir/SKILL.md" ]]; then
        printf '%s\n' "$dir"
      fi
    done | sort -u
}

list_structured_skill_dirs() {
  local base
  for base in "$REPO_ROOT/skills/my" "$REPO_ROOT/skills/vendor"; do
    [[ -d "$base" ]] || continue
    find "$base" -mindepth 1 -maxdepth 1 -type d -print0 |
      while IFS= read -r -d '' dir; do
        if [[ -f "$dir/SKILL.md" ]]; then
          printf '%s\n' "$dir"
        fi
      done
  done | sort -u
}

list_skill_names() {
  {
    list_legacy_skill_dirs | while IFS= read -r dir; do basename "$dir"; done
    list_structured_skill_dirs | while IFS= read -r dir; do basename "$dir"; done
  } | sort -u
}

resolve_source_dir() {
  local skill="$1"
  local vendor_dir

  if [[ -f "$REPO_ROOT/skills/my/$skill/SKILL.md" ]]; then
    printf '%s\n' "$REPO_ROOT/skills/my/$skill"
    return 0
  fi

  if [[ -d "$REPO_ROOT/skills/vendor" ]]; then
    vendor_dir="$(find "$REPO_ROOT/skills/vendor" -mindepth 1 -maxdepth 1 -type d \
      \( -name "$skill" -o -name "*--$skill" \) -print -quit)"
    if [[ -n "$vendor_dir" && -f "$vendor_dir/SKILL.md" ]]; then
      printf '%s\n' "$vendor_dir"
      return 0
    fi
  fi

  if [[ -f "$REPO_ROOT/$skill/SKILL.md" ]]; then
    printf '%s\n' "$REPO_ROOT/$skill"
    return 0
  fi

  return 1
}

resolve_overlay_dir() {
  local skill="$1"
  local vendor_dir

  if [[ -d "$REPO_ROOT/skills/my/$skill" ]]; then
    printf '%s\n' "$REPO_ROOT/skills/my/$skill"
    return 0
  fi

  if [[ -d "$REPO_ROOT/skills/vendor" ]]; then
    vendor_dir="$(find "$REPO_ROOT/skills/vendor" -mindepth 1 -maxdepth 1 -type d \
      \( -name "$skill" -o -name "*--$skill" \) -print -quit)"
    if [[ -n "$vendor_dir" ]]; then
      printf '%s\n' "$vendor_dir"
      return 0
    fi
  fi

  return 1
}

copy_meta_if_present() {
  local overlay_dir="$1"
  local out_dir="$2"

  if [[ -n "$overlay_dir" && -f "$overlay_dir/meta.yaml" ]]; then
    cp "$overlay_dir/meta.yaml" "$out_dir/meta.yaml"
  fi
}

write_yaml_block() {
  local yaml_file="$1"

  if [[ "$(head -n 1 "$yaml_file")" == "---" ]]; then
    cat "$yaml_file"
  else
    printf -- "---\n"
    cat "$yaml_file"
    printf -- "\n---\n"
  fi
}
