#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/Documents/老戴Ai备份外脑}"
BACKUP_ROOT="${BACKUP_ROOT:-$PROJECT_ROOT/backups/codex-weekly}"
MIRROR_DIR="${MIRROR_DIR:-$HOME/Library/Application Support/laodai-codex-backup/github-private-mirror}"
GITHUB_REMOTE_URL="${GITHUB_REMOTE_URL:-}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/laodai_codex_backup_ed25519}"
CHUNK_SIZE_MB="${CHUNK_SIZE_MB:-90}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command git
require_command openssl
require_command split

if [ -n "${LATEST_ARCHIVE:-}" ]; then
  latest_archive="$LATEST_ARCHIVE"
  latest_dir="$(dirname "$latest_archive")"
else
  latest_dir="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
  if [ -z "$latest_dir" ]; then
    echo "No local backup directory found in $BACKUP_ROOT" >&2
    exit 1
  fi
  latest_archive="$(find "$latest_dir" -maxdepth 1 -name 'codex-weekly-*.tar.gz' -type f | sort | tail -n 1)"
fi
if [ -z "$latest_archive" ]; then
  echo "No backup archive found in $latest_dir" >&2
  exit 1
fi

if [ ! -d "$MIRROR_DIR/.git" ]; then
  mkdir -p "$(dirname "$MIRROR_DIR")"
  if [ -f "$SSH_KEY_PATH" ]; then
    export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
  fi
  if [ -n "$GITHUB_REMOTE_URL" ]; then
    git clone --depth 1 "$GITHUB_REMOTE_URL" "$MIRROR_DIR"
  else
    git init "$MIRROR_DIR"
  fi
fi

mkdir -p "$MIRROR_DIR/backups" "$MIRROR_DIR/docs" "$MIRROR_DIR/scripts" "$MIRROR_DIR/launchd"

archive_name="$(basename "$latest_archive")"
encrypted_archive="$MIRROR_DIR/backups/$archive_name.enc"
chunk_prefix="$MIRROR_DIR/backups/$archive_name.enc.part-"
chunk_manifest="$MIRROR_DIR/backups/$archive_name.enc.parts.txt"

if [ -n "${CODEX_BACKUP_PASSPHRASE_FILE:-}" ]; then
  pass_arg="file:$CODEX_BACKUP_PASSPHRASE_FILE"
elif [ -n "${CODEX_BACKUP_PASSPHRASE:-}" ]; then
  pass_arg="env:CODEX_BACKUP_PASSPHRASE"
else
  printf "Encryption passphrase: "
  stty -echo
  read -r CODEX_BACKUP_PASSPHRASE
  stty echo
  printf "\n"
  export CODEX_BACKUP_PASSPHRASE
  pass_arg="env:CODEX_BACKUP_PASSPHRASE"
fi

openssl enc -aes-256-cbc -salt -pbkdf2 -iter 200000 \
  -in "$latest_archive" \
  -out "$encrypted_archive" \
  -pass "$pass_arg"

shasum -a 256 "$encrypted_archive" > "$encrypted_archive.sha256"

split_parts=1
chunk_bytes="$((CHUNK_SIZE_MB * 1024 * 1024))"
if [ "$(stat -f%z "$encrypted_archive")" -gt "$chunk_bytes" ]; then
  rm -f "$chunk_prefix"*
  split -b "${CHUNK_SIZE_MB}m" -d -a 3 "$encrypted_archive" "$chunk_prefix"
  split_parts="$(find "$MIRROR_DIR/backups" -maxdepth 1 -name "$(basename "$encrypted_archive").part-*" -type f | sort | wc -l | tr -d ' ')"
  {
    echo "# Chunked encrypted backup"
    echo
    echo "source_archive: $archive_name"
    echo "chunk_size_mb: $CHUNK_SIZE_MB"
    echo "parts: $split_parts"
    echo "reassembly: cat $(basename "$encrypted_archive").part-* > $(basename "$encrypted_archive")"
    echo "verify: shasum -a 256 $(basename "$encrypted_archive")"
  } > "$chunk_manifest"
  rm -f "$encrypted_archive"
else
  rm -f "$chunk_manifest"
fi

cp "$PROJECT_ROOT/Codex每周自动备份方案.md" "$MIRROR_DIR/docs/" 2>/dev/null || true
cp "$PROJECT_ROOT/GitHub双备份设置说明.md" "$MIRROR_DIR/docs/" 2>/dev/null || true
cp "$PROJECT_ROOT/scripts/weekly_codex_backup.sh" "$MIRROR_DIR/scripts/" 2>/dev/null || true
cp "$PROJECT_ROOT/scripts/sync_codex_backup_to_github.sh" "$MIRROR_DIR/scripts/" 2>/dev/null || true
cp "$PROJECT_ROOT/scripts/backup_and_sync_codex.sh" "$MIRROR_DIR/scripts/" 2>/dev/null || true
cp "$PROJECT_ROOT/launchd/com.laodai.codex-weekly-backup.plist" "$MIRROR_DIR/launchd/" 2>/dev/null || true
cp "$latest_dir/EXCLUDED.txt" "$MIRROR_DIR/backups/$archive_name.EXCLUDED.txt" 2>/dev/null || true

cat > "$MIRROR_DIR/README.md" <<EOF
# 老戴 Codex 加密备份镜像

本仓库用于保存 Codex 每周备份的 GitHub 侧副本。

## 安全原则

- GitHub 只保存加密后的 \`.tar.gz.enc\` 备份包。
- 原始 \`.tar.gz\` 不应提交到 GitHub。
- Codex 登录凭据、Cookies 和浏览器状态不进入备份。
- 解密密码应保存在密码管理器或离线保险箱里，不要提交到本仓库。

## 最近一次同步

- source_archive: $archive_name
- synced_at: $(date -Iseconds)
- chunks: $split_parts

## 解密示例

\`\`\`bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \\
  -in backups/$archive_name.enc \\
  -out $archive_name
\`\`\`

## 如果是分片包

\`\`\`bash
cat backups/$archive_name.enc.part-* > backups/$archive_name.enc
shasum -a 256 backups/$archive_name.enc
\`\`\`
EOF

cat > "$MIRROR_DIR/.gitignore" <<'EOF'
*.tar.gz
*.zip
.DS_Store
passphrase*
*.key
*.pem
EOF

if [ ! -d "$MIRROR_DIR/.git" ]; then
  git -C "$MIRROR_DIR" init
fi

if [ -n "$GITHUB_REMOTE_URL" ]; then
  if git -C "$MIRROR_DIR" remote get-url origin >/dev/null 2>&1; then
    git -C "$MIRROR_DIR" remote set-url origin "$GITHUB_REMOTE_URL"
  else
    git -C "$MIRROR_DIR" remote add origin "$GITHUB_REMOTE_URL"
  fi
fi

git -C "$MIRROR_DIR" add .

if git -C "$MIRROR_DIR" diff --cached --quiet; then
  echo "No GitHub mirror changes to commit."
else
  git -C "$MIRROR_DIR" commit -m "Update Codex encrypted backup $archive_name"
fi

if git -C "$MIRROR_DIR" remote get-url origin >/dev/null 2>&1; then
  if [ -f "$SSH_KEY_PATH" ]; then
    export GIT_SSH_COMMAND="ssh -i $SSH_KEY_PATH -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
  fi
  git -C "$MIRROR_DIR" branch -M main
  git -C "$MIRROR_DIR" push -u origin main
else
  echo "Local encrypted Git mirror is ready at:"
  echo "$MIRROR_DIR"
  echo
  echo "Set GITHUB_REMOTE_URL and rerun this script after creating a private GitHub repository."
fi
