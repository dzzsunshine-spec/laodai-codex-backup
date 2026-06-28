#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/Documents/老戴Ai备份外脑}"
PASSPHRASE_FILE="${CODEX_BACKUP_PASSPHRASE_FILE:-$HOME/.codex-backup-passphrase}"
REMOTE_URL="${GITHUB_REMOTE_URL:-git@github.com:dzzsunshine-spec/laodai-codex-backup.git}"
MIRROR_DIR="${MIRROR_DIR:-$HOME/Library/Application Support/laodai-codex-backup/github-private-mirror}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_FILE="$(mktemp "${TMPDIR:-/tmp}/laodai-codex-backup.XXXXXX")"
LATEST_ARCHIVE=""

notify() {
  local title="$1"
  local message="$2"
  /usr/bin/osascript - "$title" "$message" <<'APPLESCRIPT' >/dev/null 2>&1 || true
on run argv
  display notification (item 2 of argv) with title (item 1 of argv)
end run
APPLESCRIPT
}

cleanup() {
  rm -f "$RESULT_FILE"
}

on_error() {
  local exit_code=$?
  cleanup
  notify "Codex 备份失败" "本地或 GitHub 双备份没有完成，请查看 weekly-backup-and-github-sync.err。"
  exit "$exit_code"
}

trap on_error ERR
trap cleanup EXIT

BACKUP_RESULT_FILE="$RESULT_FILE" "$SCRIPT_DIR/weekly_codex_backup.sh"
LATEST_ARCHIVE="$(cat "$RESULT_FILE")"

CODEX_BACKUP_PASSPHRASE_FILE="$PASSPHRASE_FILE" \
GITHUB_REMOTE_URL="$REMOTE_URL" \
MIRROR_DIR="$MIRROR_DIR" \
LATEST_ARCHIVE="$LATEST_ARCHIVE" \
"$SCRIPT_DIR/sync_codex_backup_to_github.sh"

archive_name="$(basename "$LATEST_ARCHIVE")"
notify "Codex 双备份完成" "本地备份和 GitHub 加密备份已完成：$archive_name"
