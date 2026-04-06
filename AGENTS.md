# AGENTS.md — ghostty-optimization

## Recording Protocol (MANDATORY)

This project uses AgenticOS for persistent context management.
All session activity MUST be recorded via MCP tools.

### How to Record

Call the MCP tool `agenticos_record` with:
- `summary` (required): What happened in this session
- `decisions`: Key decisions made
- `outcomes`: What was accomplished
- `pending`: What remains to be done
- `current_task`: { title, status } to update current task

### When to Record

1. After completing any meaningful unit of work
2. Before ending the session (MANDATORY — context is lost otherwise)

After recording, call `agenticos_save` to commit to Git.

### Session Start

On session start, read these files for context:
1. `.project.yaml` — Project metadata
2. `.context/state.yaml` — Current state and working memory
3. `.context/conversations/` — Previous session records

Then greet the user with: project name, last progress, current pending items, suggested next step.

## Project

**Name**: ghostty-optimization
**Description**: Ghostty + Cmux + Zed AI 多协作编程终端栈 — 配置备份、跨机器恢复、性能优化

## Directory Structure

| Path | Purpose |
|------|---------|
| `.project.yaml` | Project metadata |
| `.context/state.yaml` | Session state and working memory |
| `.context/conversations/` | Session records (auto-generated) |
| `knowledge/` | Persistent knowledge documents |
| `tasks/` | Task tracking |
| `artifacts/` | Outputs and deliverables |
| `setup/bootstrap.sh` | 新机器初始化脚本 |
| `setup/backup/` | 当前机器真实配置备份 |
| `tests/bootstrap.bats` | 单元测试（bats-core）|

---

## New Machine Setup (Agent Instructions)

### 完整安装 Guide

> **Canonical source**: [README.md](./README.md) — 新机器安装步骤、维护文档
> **Canonical checklist**: `bash setup/verify.sh` — 安装后验证（所有 Agent 通用）

### Quick Install (copy-paste ready)

**方式 A — Homebrew（推荐）**
```bash
brew tap madlouse/ghostty https://github.com/madlouse/homebrew-ghostty
brew install ghostty-cmux
ghostty-cmux-sync
```

**方式 B — 手动克隆**
```bash
git clone https://github.com/madlouse/ghostty-optimization.git ~/dev/ghostty-optimization
cd ~/dev/ghostty-optimization
bash setup/sync.sh
```

### 验证（幂等，可重复执行）

```bash
bash setup/verify.sh
```

### Known Issues & Fixes

| 问题 | 原因 | 修复 |
|------|------|------|
| `brew install` 报 "No formula zed/cmux" | 旧版 formula 把 cask 写成 formula | `brew untap madlouse/ghostty && brew tap madlouse/ghostty` 刷新 |
| `.zshrc` 恢复后与原机器不同 | 安装前本机有自定义内容未迁移 | 把自定义内容放入 `~/.zshrc.local`，再 `bash bootstrap.sh --force` |
| Ghostty theme 不生效 | `copy-on-select = clipboard` 与 Cmux 冲突 | `sed -i '' 's/copy-on-select = clipboard/copy-on-select = false/' ~/.config/ghostty/config` |
| API keys 未配置 | `~/.env.local` 是模板，需手动填写 | `vim ~/.env.local` |

### bootstrap.sh 幂等行为

| 场景 | 行为 |
|------|------|
| 配置文件已与备份一致 | **跳过**（`[→] 已一致，跳过`）|
| 配置文件内容不一致 | 覆盖（旧版备份至 `~/.config-backup/`）|
| `.zshrc` 有幂等标记且内容一致 | **跳过** |
| `.env.local` / `.zshrc.local` 已存在 | **跳过**（不覆盖）|
| `brew bundle install` 重复运行 | **跳过**（Homebrew bundle 本身幂等）|
| 强制重新部署 | `bash bootstrap.sh --force` |

### What bootstrap.sh Deploys

| 源文件 | 目标路径 | 策略 |
|--------|----------|------|
| `setup/backup/ghostty-config` | `~/.config/ghostty/config` | diff 检查后覆盖 |
| `setup/backup/starship.toml` | `~/.config/starship.toml` | diff 检查后覆盖 |
| `setup/backup/zprofile` | `~/.zprofile` | diff 检查后覆盖 |
| `setup/backup/zshrc` | `~/.zshrc` | 标记存在则跳过，否则覆盖 |
| `setup/backup/zshrc.local.example` | `~/.zshrc.local` | 仅首次创建 |
| `setup/backup/env.local.example` | `~/.env.local` | 仅首次创建 |
| `setup/backup/zed/settings.json` | `~/.config/zed/settings.json` | diff 检查后覆盖 |
| `setup/backup/zsh-completions/_opencli` | `~/.zsh/completions/_opencli` | diff 检查后覆盖 |
| `setup/backup/claude-hooks/cmux-notify-hook.sh` | `~/.claude/hooks/cmux-notify-hook.sh` | diff 检查后覆盖 |
