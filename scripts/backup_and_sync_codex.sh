#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/Documents/老戴Ai备份外脑}"
PASSPHRASE_FILE="${CODEX_BACKUP_PASSPHRASE_FILE:-$HOME/.codex-backup-passphrase}"
REMOTE_URL="${GITHUB_REMOTE_URL:-git@github.com:dzzsunshine-spec/laodai-codex-backup.git}"

"$PROJECT_ROOT/scripts/weekly_codex_backup.sh"

CODEX_BACKUP_PASSPHRASE_FILE="$PASSPHRASE_FILE" \
GITHUB_REMOTE_URL="$REMOTE_URL" \
"$PROJECT_ROOT/scripts/sync_codex_backup_to_github.sh"
