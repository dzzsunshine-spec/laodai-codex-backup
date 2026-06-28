# GitHub 双备份设置说明

## 结论

可以做 GitHub 双备份，但建议采用这个结构：

- 本地：保存原始 Codex 备份包。
- GitHub 私有仓库：只保存加密后的备份包、备份脚本和说明文档。
- Mac 端：作为 GitHub 同步主设备。
- 手机端：只建议查看和轻量编辑，不建议一开始承担 Git 同步。

不要把原始会话记录、账号凭据、Cookies 或未加密压缩包直接推到 GitHub。

## 上传边界

不得上传到 GitHub：

1. 密码；
2. API Key；
3. 1Password Secret Key；
4. 身份证；
5. 银行卡；
6. 合同原件；
7. 客户隐私明细；
8. 未脱敏财务数据；
9. 家庭敏感信息；
10. 任何无法承担泄露风险的资料。

推荐上传到私有仓库的内容：

1. AI 协作宪法；
2. 人格镜子档案；
3. 高风险决策风控；
4. 迁移保险箱；
5. 表达风格；
6. 低敏项目档案；
7. 低敏人物关系摘要；
8. 重大经历方法论；
9. 新 GPT 或新 Codex 初始化提示词。

## 第一步：创建 GitHub 账号

账号必须由你本人创建，因为需要邮箱、密码、验证码和可能的双重验证。

入口：

- `https://github.com/signup`

建议：

- 使用你长期可控的邮箱。
- 开启双重验证。
- 把 GitHub 密码和恢复码放进密码管理器。

## 第二步：创建私有仓库

登录 GitHub 后，新建仓库：

- Repository name：`laodai-codex-backup`
- Visibility：`Private`
- 不要勾选公开。

创建后 GitHub 会给你一个远程地址，通常长这样：

```text
https://github.com/你的用户名/laodai-codex-backup.git
```

## 第三步：本地生成加密镜像

先确保已经有本地备份：

```bash
"/Users/daizhengzhou/Documents/老戴Ai备份外脑/scripts/weekly_codex_backup.sh"
```

然后运行 GitHub 同步脚本：

```bash
"/Users/daizhengzhou/Documents/老戴Ai备份外脑/scripts/sync_codex_backup_to_github.sh"
```

脚本会要求输入加密密码。这个密码必须保存好；没有它，GitHub 上的 `.enc` 文件无法恢复。

## 第四步：连接 GitHub 私有仓库

把下面命令里的地址换成你的仓库地址：

```bash
GITHUB_REMOTE_URL="https://github.com/你的用户名/laodai-codex-backup.git" \
"/Users/daizhengzhou/Documents/老戴Ai备份外脑/scripts/sync_codex_backup_to_github.sh"
```

第一次推送时，GitHub 可能要求登录或输入 token。建议使用 GitHub Personal Access Token，并把 token 保存在 macOS 钥匙串或密码管理器。

## 每周自动同步的建议

最稳的做法是：

1. 每周一先运行本地备份脚本。
2. 再运行 GitHub 同步脚本。
3. GitHub 上只出现 `.tar.gz.enc`，不出现 `.tar.gz`。
4. 重大系统更新后立即手动同步一次。
5. 每月额外导出压缩包到云盘或移动硬盘。

当前已经提供一键脚本：

```bash
"/Users/daizhengzhou/Documents/老戴Ai备份外脑/scripts/backup_and_sync_codex.sh"
```

如果以后要完全无人值守，可以把加密密码放到本机受保护文件里：

```bash
printf "你的强密码" > "$HOME/.codex-backup-passphrase"
chmod 600 "$HOME/.codex-backup-passphrase"
```

然后这样运行：

```bash
CODEX_BACKUP_PASSPHRASE_FILE="$HOME/.codex-backup-passphrase" \
GITHUB_REMOTE_URL="git@github.com:dzzsunshine-spec/laodai-codex-backup.git" \
"/Users/daizhengzhou/Documents/老戴Ai备份外脑/scripts/sync_codex_backup_to_github.sh"
```

注意：密码文件放在本机，主要防 GitHub 泄露，不防本机被完全攻破。最高安全做法是把密码放进 1Password、Bitwarden、iCloud Keychain 或纸质保险箱。

## 恢复方式

从 GitHub 下载 `.enc` 文件后，用下面命令解密：

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -in codex-weekly-YYYYMMDD-HHMMSS.tar.gz.enc \
  -out codex-weekly-YYYYMMDD-HHMMSS.tar.gz
```

再解压：

```bash
tar -xzf codex-weekly-YYYYMMDD-HHMMSS.tar.gz
```

恢复顺序仍然是：先规则和配置，再技能，再记忆和会话。
