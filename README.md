# 老戴 Codex 加密备份镜像

本仓库用于保存 Codex 每周备份的 GitHub 侧副本。

## 安全原则

- GitHub 只保存加密后的 `.tar.gz.enc` 备份包。
- 原始 `.tar.gz` 不应提交到 GitHub。
- Codex 登录凭据、Cookies 和浏览器状态不进入备份。
- 解密密码应保存在密码管理器或离线保险箱里，不要提交到本仓库。

## 最近一次同步

- source_archive: codex-weekly-20260720-095834.tar.gz
- synced_at: 2026-07-20T09:58:46+08:00
- chunks: 3

## 解密示例

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -in backups/codex-weekly-20260720-095834.tar.gz.enc \
  -out codex-weekly-20260720-095834.tar.gz
```

## 如果是分片包

```bash
cat backups/codex-weekly-20260720-095834.tar.gz.enc.part-* > backups/codex-weekly-20260720-095834.tar.gz.enc
shasum -a 256 backups/codex-weekly-20260720-095834.tar.gz.enc
```
