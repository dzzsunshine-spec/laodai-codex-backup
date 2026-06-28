# Codex 每周自动备份方案

## 结论

这份 `AI账号迁移保险箱使用说明` 的核心不是普通文件备份，而是保护 AI 长期协作资产：规则、记忆、技能、会话、方法论、工作流和迁移时能重新投喂给新账号的上下文。

对 Codex 来说，最应该每周自动备份的是 `~/.codex` 里的核心逻辑资产，再加上 `~/.agents` 里的自定义 Agent 能力。账号登录凭据不要直接放进普通备份，应单独放到 1Password、iCloud Keychain、Bitwarden 或加密磁盘映像里。

## 本机当前识别到的资产

- `~/.codex/AGENTS.md`：全局规则，目前内容是“所有的项目都要遵照：老戴 AI 规则 SOP”。
- `~/.codex/config.toml`：Codex 配置。
- `~/.codex/sessions`：会话记录，是恢复隐性上下文的重要材料。
- `~/.codex/session_index.jsonl`：会话索引。
- `~/.codex/memories`：Codex 记忆仓库，目前还是初始化状态，后续会越来越重要。
- `~/.codex/skills`：你安装或创建的技能，其中包括 `ima-skill`、`workctl` 等。
- `~/.codex/shell_snapshots`：部分终端上下文。
- `~/.codex/ambient-suggestions`：环境建议和辅助上下文。
- `~/.agents/skills`：Work Agent 相关技能。

## 不建议直接备份的内容

- `~/.codex/auth.json`：登录凭据，建议单独加密保存。
- `~/.codex/*.sqlite`、`*.sqlite-wal`、`*.sqlite-shm`：运行态数据库，直接冷复制可能不稳定。
- `~/.codex/plugins/cache`、`.tmp`、`tmp`、`node_repl`、`process_manager`：缓存和临时运行目录，可重新生成。
- `~/Library/Application Support/Codex`：浏览器配置状态里可能包含 Cookies，不作为默认备份内容。

## 已放入本目录的自动备份工具

- `scripts/weekly_codex_backup.sh`
- `scripts/sync_codex_backup_to_github.sh`
- `scripts/backup_and_sync_codex.sh`
- `launchd/com.laodai.codex-weekly-backup.plist`
- `GitHub双备份设置说明.md`

脚本每次运行会生成：

- `backups/codex-weekly/YYYYMMDD-HHMMSS/codex-weekly-YYYYMMDD-HHMMSS.tar.gz`
- `MANIFEST.md`：本次备份包含哪些文件。
- `EXCLUDED.txt`：本次故意排除哪些内容。
- `.sha256`：校验文件，判断备份包有没有损坏。

## 手动跑一次

```bash
chmod +x "/Users/daizhengzhou/Documents/老戴Ai备份外脑/scripts/weekly_codex_backup.sh"
"/Users/daizhengzhou/Documents/老戴Ai备份外脑/scripts/weekly_codex_backup.sh"
```

## 设置每周自动运行

当前定时配置是每周一 09:30 自动执行“两边备份”：先生成本地原始备份，再把加密副本推送到 GitHub 私有仓库。

备份结束后会通过 macOS 通知提醒：

- 成功：提示本地备份和 GitHub 加密备份已完成。
- 失败：提示检查 `weekly-backup-and-github-sync.err`。

定时任务实际调用的脚本会安装到：

```text
/Users/daizhengzhou/Library/Scripts/laodai-codex-backup/
```

定时任务使用的 GitHub 镜像目录会放在：

```text
/Users/daizhengzhou/Library/Application Support/laodai-codex-backup/github-private-mirror/
```

```bash
mkdir -p "$HOME/Library/LaunchAgents"
cp "/Users/daizhengzhou/Documents/老戴Ai备份外脑/launchd/com.laodai.codex-weekly-backup.plist" "$HOME/Library/LaunchAgents/"
launchctl load "$HOME/Library/LaunchAgents/com.laodai.codex-weekly-backup.plist"
```

想立刻测试定时任务：

```bash
launchctl start com.laodai.codex-weekly-backup
```

## 推荐的三层备份

第一层：本机自动备份

- 由 `weekly_codex_backup.sh` 每周生成压缩包。
- 适合快速恢复。

第二层：GitHub 私有仓库

- 只同步加密后的备份包、Markdown 说明和脚本。
- 不把完整会话和可能含敏感信息的原始压缩包直接推到 GitHub。
- 具体设置见 `GitHub双备份设置说明.md`。
- GitHub 同步以 Mac 端为主，不建议一开始在手机端折腾 Git 同步。

第三层：云盘或硬盘冷备份

- 每月至少把 `backups/codex-weekly` 复制到 iCloud Drive、Google Drive、阿里云盘、移动硬盘或 NAS。
- 建议保留最近 12 周周备份 + 最近 12 个月月备份。

## 每周备份后要做的检查

- 看 `backups/codex-weekly` 是否出现新的日期目录。
- 打开 `MANIFEST.md`，确认包含 `codex/sessions`、`codex/memories`、`codex/skills`、`codex/AGENTS.md`。
- 用 `.sha256` 校验压缩包没有损坏。
- 打开 GitHub 私有仓库，确认只出现 `.tar.gz.enc`，没有未加密的 `.tar.gz`。
- 每月至少做一次恢复演练：解压到临时目录，确认关键文件存在。

## GitHub 上传边界

不得上传：

- 密码、API Key、1Password Secret Key。
- 身份证、银行卡、合同原件。
- 客户隐私明细、未脱敏财务数据。
- 家庭敏感信息。
- 任何无法承担泄露风险的资料。

适合上传到私有仓库的低敏材料：

- AI 协作宪法。
- 风控边界和迁移保险箱摘要。
- 表达风格、低敏项目档案、低敏人物关系摘要。
- 重大经历方法论。
- 新 Codex 或新 GPT 初始化提示词。

频率规则：

- 每周自动两边备份一次。
- 重大系统更新后立即手动同步一次。
- 每月至少额外导出压缩包到云盘或移动硬盘。

## 迁移到新 Codex 账号时的恢复顺序

1. 安装并登录新的 Codex。
2. 先恢复 `AGENTS.md`、`config.toml`、`skills`。
3. 再恢复 `memories` 和关键会话材料。
4. 把保险箱摘要投喂给新账号，让新账号先读“规则、偏好、长期目标、工作流、风控边界”。
5. 用 1-2 周高质量互动补回语气默契和隐性判断。

## 建议新增的保险箱摘要

每周除了压缩包，还应该生成或维护一份人类可读的 `Codex迁移总索引.md`，包含：

- 老戴 AI 规则 SOP 的完整内容或入口。
- 当前 Codex 的核心工作流。
- 已安装技能及用途。
- 重要项目列表。
- 关键长期偏好。
- 高风险事项边界。
- 最近 4 周关键会话摘要。

压缩包负责“尽量完整”，总索引负责“新 AI 能快速理解你”。
