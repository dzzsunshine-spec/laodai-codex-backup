#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/Documents/老戴Ai备份外脑}"
PASSPHRASE_FILE="${CODEX_BACKUP_PASSPHRASE_FILE:-$HOME/.codex-backup-passphrase}"
REMOTE_URL="${GITHUB_REMOTE_URL:-git@github.com:dzzsunshine-spec/laodai-codex-backup.git}"
MIRROR_DIR="${MIRROR_DIR:-$HOME/Library/Application Support/laodai-codex-backup/github-private-mirror}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$(mktemp "${TMPDIR:-/tmp}/laodai-codex-backup.XXXXXX")"

BACKUP_RESULT_FILE="$RESULT_FILE" "$SCRIPT_DIR/weekly_codex_backup.sh"
LATEST_ARCHIVE="$(cat "$RESULT_FILE")"
rm -f "$RESULT_FILE"

CODEX_BACKUP_PASSPHRASE_FILE="$PASSPHRASE_FILE" \
GITHUB_REMOTE_URL="$REMOTE_URL" \
MIRROR_DIR="$MIRROR_DIR" \
LATEST_ARCHIVE="$LATEST_ARCHIVE" \
"$SCRIPT_DIR/sync_codex_backup_to_github.sh"
