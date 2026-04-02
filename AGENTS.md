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

> 以下步骤适用于在**新机器**上恢复完整环境。Agent 可直接执行。

### 方式 A: Homebrew（推荐）

```bash
# Step 1: 安装
brew tap madlouse/ghostty https://github.com/madlouse/homebrew-ghostty
brew install ghostty-cmux

# Step 2: 部署配置（bootstrap 由 post_install 自动触发）
# 如需手动重新部署：
bash /opt/homebrew/opt/ghostty-cmux/libexec/ghostty-optimization/setup/bootstrap.sh
```

### 方式 B: 手动克隆

```bash
git clone https://github.com/madlouse/ghostty-optimization.git ~/dev/ghostty-optimization
cd ~/dev/ghostty-optimization
bash setup/bootstrap.sh
```

### Post-Install Verification Checklist

运行以下命令验证安装结果，**所有项均应输出** ✓ 或对应路径：

```bash
# 1. 配置文件已部署
[ -f ~/.config/ghostty/config ] && echo "✓ ghostty config" || echo "✗ ghostty config MISSING"
[ -f ~/.config/starship.toml ]  && echo "✓ starship config" || echo "✗ starship config MISSING"
[ -f ~/.config/zed/settings.json ] && echo "✓ zed config" || echo "✗ zed config MISSING"
[ -f ~/.zshrc ]                 && echo "✓ zshrc" || echo "✗ zshrc MISSING"
[ -f ~/.env.local ]             && echo "✓ env.local" || echo "✗ env.local MISSING"

# 2. CLI 工具可用
command -v starship  && echo "✓ starship"  || echo "✗ starship NOT FOUND"
command -v fastfetch && echo "✓ fastfetch" || echo "✗ fastfetch NOT FOUND"
command -v btop      && echo "✓ btop"      || echo "✗ btop NOT FOUND"

# 3. 应用已安装
ls /Applications/Ghostty.app &>/dev/null && echo "✓ Ghostty" || echo "✗ Ghostty NOT FOUND"
ls /Applications/Zed.app      &>/dev/null && echo "✓ Zed"     || echo "✗ Zed NOT FOUND"
ls /Applications/Cmux.app     &>/dev/null && echo "✓ Cmux"    || echo "✗ Cmux NOT FOUND"

# 4. Ghostty 配置关键项验证
grep -q "font-size = 16" ~/.config/ghostty/config      && echo "✓ font-size=16" || echo "✗ font-size mismatch"
grep -q "Catppuccin" ~/.config/ghostty/config          && echo "✓ theme=Catppuccin" || echo "✗ theme mismatch"
grep -q "copy-on-select = false" ~/.config/ghostty/config && echo "✓ copy-on-select=false" || echo "✗ copy-on-select mismatch"
```

### Known Issues & Fixes

| 问题 | 原因 | 修复 |
|------|------|------|
| `brew install` 报 "No formula zed/cmux" | 旧版 formula 把 cask 写成 formula | `brew untap madlouse/ghostty && brew tap madlouse/ghostty` 刷新 |
| `.zshrc` 恢复后与原机器不同 | 安装前本机有自定义内容未迁移 | 把自定义内容放入 `~/.zshrc.local`，再重新运行 bootstrap |
| Ghostty theme 不生效 | `copy-on-select = clipboard` 与 Cmux 冲突 | `sed -i '' 's/copy-on-select = clipboard/copy-on-select = false/' ~/.config/ghostty/config` |
| API keys 未配置 | `~/.env.local` 是模板，需手动填写 | `vim ~/.env.local` |

### What bootstrap.sh Deploys

| 文件 | 目标路径 | 策略 |
|------|----------|------|
| `setup/backup/ghostty-config` | `~/.config/ghostty/config` | 覆盖（旧版 → `~/.config-backup/`）|
| `setup/backup/starship.toml` | `~/.config/starship.toml` | 覆盖（旧版 → `~/.config-backup/`）|
| `setup/backup/zprofile` | `~/.zprofile` | 覆盖（旧版 → `~/.config-backup/`）|
| `setup/backup/zshrc` | `~/.zshrc` | **全量覆盖**（旧版 → `~/.config-backup/`）|
| `setup/backup/zshrc.local.example` | `~/.zshrc.local` | 仅首次创建 |
| `setup/backup/env.local.example` | `~/.env.local` | 仅首次创建 |
| `setup/backup/zed/settings.json` | `~/.config/zed/settings.json` | 覆盖（旧版 → `~/.config-backup/`）|
| `setup/backup/zsh-completions/_opencli` | `~/.zsh/completions/_opencli` | 覆盖 |
| `setup/backup/claude-hooks/cmux-notify-hook.sh` | `~/.claude/hooks/cmux-notify-hook.sh` | 覆盖 |
