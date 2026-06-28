# 老戴 Codex 加密备份镜像

本仓库用于保存 Codex 每周备份的 GitHub 侧副本。

## 安全原则

- GitHub 只保存加密后的 `.tar.gz.enc` 备份包。
- 原始 `.tar.gz` 不应提交到 GitHub。
- Codex 登录凭据、Cookies 和浏览器状态不进入备份。
- 解密密码应保存在密码管理器或离线保险箱里，不要提交到本仓库。

## 最近一次同步

- source_archive: codex-weekly-20260628-130741.tar.gz
- synced_at: 2026-06-28T13:17:19+08:00

## 解密示例

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -in backups/codex-weekly-20260628-130741.tar.gz.enc \
  -out codex-weekly-20260628-130741.tar.gz
```
