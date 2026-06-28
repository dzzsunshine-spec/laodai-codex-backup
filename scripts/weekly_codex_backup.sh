#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-$HOME/Documents/老戴Ai备份外脑/backups/codex-weekly}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
AGENTS_HOME="${AGENTS_HOME:-$HOME/.agents}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$BACKUP_ROOT/$timestamp"
staging="$backup_dir/staging"
archive="$backup_dir/codex-weekly-$timestamp.tar.gz"

mkdir -p "$staging"

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    rsync -a "$src" "$dst"
  fi
}

copy_codex_dir() {
  local name="$1"
  if [ -e "$CODEX_HOME/$name" ]; then
    rsync -a "$CODEX_HOME/$name" "$staging/codex/"
  fi
}

mkdir -p "$staging/codex" "$staging/agents" "$backup_dir"

# Core Codex knowledge assets: conversations, memory, custom skills, global rules,
# shell context, lightweight indexes, and non-secret configuration.
copy_codex_dir "AGENTS.md"
copy_codex_dir "config.toml"
copy_codex_dir "sessions"
copy_codex_dir "session_index.jsonl"
copy_codex_dir "memories"
copy_codex_dir "skills"
copy_codex_dir "shell_snapshots"
copy_codex_dir "ambient-suggestions"
copy_codex_dir ".personality_migration"
copy_codex_dir ".codex-global-state.json"
copy_codex_dir ".codex-global-state.json.bak"
copy_codex_dir "installation_id"

# Work Agent / custom agent skills.
if [ -d "$AGENTS_HOME" ]; then
  rsync -a \
    --exclude "_agents.mount_config" \
    "$AGENTS_HOME/" "$staging/agents/"
fi

# Explicitly do not copy secrets or volatile runtime databases.
cat > "$backup_dir/EXCLUDED.txt" <<'EOF'
Excluded by design:
- ~/.codex/auth.json and account tokens
- ~/.codex/*.sqlite, *.sqlite-wal, *.sqlite-shm runtime databases
- ~/.codex/plugins/cache and other downloaded runtime caches
- ~/.codex/.tmp, ~/.codex/tmp, ~/.codex/node_repl, ~/.codex/process_manager
- ~/Library/Application Support/Codex browser profile state, including cookies

Reason:
This backup is for Codex logic, memory, skills, rules, sessions, and restoration context.
Credentials should be stored separately in an encrypted password manager or encrypted vault.
EOF

{
  echo "# Codex Weekly Backup Manifest"
  echo
  echo "- created_at: $(date -Iseconds)"
  echo "- host: $(hostname)"
  echo "- backup_dir: $backup_dir"
  echo "- codex_home: $CODEX_HOME"
  echo "- agents_home: $AGENTS_HOME"
  echo
  echo "## Included"
  find "$staging" -type f | sed "s#^$staging/##" | sort
} > "$backup_dir/MANIFEST.md"

tar -C "$staging" -czf "$archive" .
shasum -a 256 "$archive" > "$archive.sha256"

rm -rf "$staging"

echo "Backup archive created:"
echo "$archive"
echo
echo "Checksum:"
cat "$archive.sha256"
