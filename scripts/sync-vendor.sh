#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/sync-vendor.sh <source> <target-slug> [source-subpath]

Examples:
  ./scripts/sync-vendor.sh https://github.com/example/skills.git example--my-skill path/to/skill
  ./scripts/sync-vendor.sh /absolute/path/to/exported-skill local--my-skill
  ./scripts/sync-vendor.sh clawhub://github github
EOF
}

[[ $# -ge 2 ]] || {
  usage
  exit 1
}

SOURCE="$1"
TARGET_SLUG="$2"
SOURCE_SUBPATH="${3:-}"
DEST_DIR="$REPO_ROOT/skills/vendor/$TARGET_SLUG"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

copy_skill_dir() {
  local source_dir="$1"
  [[ -f "$source_dir/SKILL.md" ]] || die "expected $source_dir/SKILL.md"

  rm -rf "$DEST_DIR"
  mkdir -p "$DEST_DIR"
  rsync -a --delete --exclude '.git' "$source_dir"/ "$DEST_DIR"/
}

if [[ "$SOURCE" == clawhub://* ]]; then
  slug="${SOURCE#clawhub://}"
  command -v npx >/dev/null 2>&1 || die "npx is required for clawhub:// sources"

  (
    cd "$TMP_DIR"
    CLAWHUB_WORKDIR="$TMP_DIR" npx clawhub@latest install "$slug" --force
  )

  installed_skill="$(find "$TMP_DIR" -type f -name 'SKILL.md' -print -quit)"
  [[ -n "$installed_skill" ]] || die "could not find installed ClawHub skill for $slug"
  copy_skill_dir "$(dirname "$installed_skill")"
elif [[ -d "$SOURCE" ]]; then
  source_dir="$SOURCE"
  if [[ -n "$SOURCE_SUBPATH" ]]; then
    source_dir="$SOURCE/$SOURCE_SUBPATH"
  fi
  copy_skill_dir "$source_dir"
else
  command -v git >/dev/null 2>&1 || die "git is required for repository sources"

  git clone --depth=1 "$SOURCE" "$TMP_DIR/repo" >/dev/null
  source_dir="$TMP_DIR/repo"
  if [[ -n "$SOURCE_SUBPATH" ]]; then
    source_dir="$source_dir/$SOURCE_SUBPATH"
  fi
  copy_skill_dir "$source_dir"
fi

printf '%s\n' "$SOURCE" > "$DEST_DIR/.vendor-source"
log "synced vendor skill to skills/vendor/$TARGET_SLUG"
