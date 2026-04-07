# Ghostty + Cmux + Zed — AI Agent 多协作编程平台

> **安装入口**: `brew install ghostty-cmux`（详见 [Setup Repository](https://github.com/madlouse/homebrew-ghostty)）
>
> **配置文件源码**: 本仓库

## 架构

```
┌─────────────────────────────────────────────┐
│  Cmux (AI 指挥中心)                          │
│  ├ 多 Agent 会话并行管理                      │
│  ├ 内置 libghostty 渲染 (GPU 加速)           │
│  ├ Agent 通知系统 (完成/等待/错误)            │
│  └ 内置浏览器 (WebKit)                        │
├─────────────────────────────────────────────┤
│  Zed (代码编辑器)                             │
│  ├ AI Agent Panel (Claude/GPT 多模型)         │
│  ├ MCP Server 集成                           │
│  └ 文件浏览 / 编辑                            │
├─────────────────────────────────────────────┤
│  Ghostty (终端基座)                          │
│  ├ 独立使用：轻量单 Agent 模式                │
│  ├ Cmux 模式：配置由 libghostty 共用          │
│  └ 统一配置: ~/.config/ghostty/config         │
└─────────────────────────────────────────────┘
```

## 一键安装

```bash
# 新电脑，一行命令搞定
brew tap madlouse/ghostty https://github.com/madlouse/homebrew-ghostty
brew install ghostty-cmux

# 之后同步最新配置
ghostty-cmux-sync
```

或手动运行（直接克隆本仓库）：

```bash
git clone https://github.com/madlouse/ghostty-optimization.git ~/dev/ghostty-optimization
cd ~/dev/ghostty-optimization
bash setup/sync.sh
```

## 文件结构

```
setup/
├── bootstrap.sh              # 初始化脚本 (由 Homebrew 或手动调用)
├── backup/                   # ★ 当前机器真实配置（已同步到仓库）
│   ├── Brewfile              # 全部 brew 包列表
│   ├── ghostty-config        # Ghostty 配置
│   ├── starship.toml         # Starship prompt 配置
│   ├── zprofile              # .zprofile
│   ├── zshrc                 # 完整可移植 .zshrc（覆盖部署，旧版先备份）
│   ├── zshrc.local.example   # 本机专属配置模板（首次创建）
│   ├── env.local.example     # API keys 模板（首次创建，不覆盖）
│   ├── zed/settings.json     # Zed 配置
│   ├── zsh-completions/      # Zsh 补全 (_opencli)
│   └── claude-hooks/         # Claude Code Hooks (Cmux 通知)
├── configs/                  # 配置模板（不含敏感信息）
│   ├── ghostty-config        # Ghostty 配置模板
│   ├── zed-settings.json     # Zed 配置模板
│   └── cmux-notify-hook.sh  # Cmux 通知 Hook
└── README.md                 # 本文件

optimizations/                # Ghostty 性能 / UX / 主题优化
resources/                   # 研究文档
benchmarks/                  # 性能测试方法
current-config/              # Ghostty 当前配置备份
```

## 两种使用模式

### 模式 A: 多 Agent 协作 (Cmux + Zed)

```bash
open -a Cmux              # 启动 Cmux
cw .                      # 为当前目录新建 Workspace
cw ~/dev/myproject        # 为指定目录新建 Workspace
cc                        # 右侧分屏 + 启动 Claude Code
cb https://docs.example.com  # 在当前 Workspace 打开内置浏览器

zed .                     # 打开当前目录
zed file.py               # 打开文件
```

`cw` 可以从普通 shell 或 Cmux 终端运行；`cc` / `cb` 需要在 Cmux 终端内运行，因为它们会操作当前 workspace。

### 模式 B: 轻量独立 (Ghostty)

```bash
open -a Ghostty           # 启动 Ghostty
Cmd+Alt+D                 # Ghostty 原生分屏
Ctrl+`                    # Quick Terminal (全局呼出)
```

## 配置说明

| 工具 | 配置路径 | 来源 | 部署方式 |
|------|----------|------|----------|
| Ghostty / Cmux | `~/.config/ghostty/config` | `setup/backup/ghostty-config` | 覆盖（旧版备份至 `~/.config-backup/`）|
| Cmux Automation | `~/.config/cmux/settings.json` | bootstrap 动态生成 | 写入 `automation.socketControlMode = automation` |
| Starship | `~/.config/starship.toml` | `setup/backup/starship.toml` | 覆盖（旧版备份）|
| Zed | `~/.config/zed/settings.json` | `setup/backup/zed/settings.json` | 覆盖（旧版备份）|
| Shell | `~/.zshrc` | `setup/backup/zshrc` | **全量覆盖**（旧版备份至 `~/.config-backup/`）|
| API Keys | `~/.env.local` | `setup/backup/env.local.example` | 仅首次创建，不覆盖 |
| 本机专属 | `~/.zshrc.local` | `setup/backup/zshrc.local.example` | 仅首次创建，不覆盖 |

> ⚠️ **注意**: `.zshrc` 采用全量覆盖，安装前请将自定义内容迁移到 `~/.zshrc.local`。
>
> `cw / cc / cb` 依赖 Cmux socket automation。`bootstrap.sh` 会写入 `~/.config/cmux/settings.json`，将 `automation.socketControlMode` 设为 `automation`，这样外部 shell 才能稳定调用 `cmux ping`、`cmux new-workspace` 等 CLI。

## 更新配置

当前机器配置变更后，同步到仓库：

```bash
cd ~/dev/ghostty-optimization
cp ~/.config/ghostty/config setup/backup/ghostty-config
cp ~/.config/starship.toml setup/backup/starship.toml
cp ~/.config/zed/settings.json setup/backup/zed/settings.json
cp ~/.zprofile setup/backup/zprofile
cp ~/.zshrc setup/backup/zshrc
cp ~/.zsh/completions/_opencli setup/backup/zsh-completions/_opencli
cp ~/.claude/hooks/cmux-notify-hook.sh setup/backup/claude-hooks/
git add -A && git commit -m "sync: update configs" && git push
```

Homebrew formula 只负责发放 bootstrap / sync 入口；最新配置通过 `ghostty-cmux-sync` 或 `bash setup/sync.sh` 从 `main` 分支快照拉取。
这意味着日常配置更新不再依赖每次都 bump formula release。

## 安装验证

安装完成后，运行幂等验证脚本检查所有配置状态：

```bash
bash setup/verify.sh
```

`verify.sh` 现在会同时检查：
- `~/.config/cmux/settings.json` 是否把 `socketControlMode` 设为 `automation`
- `cmux ping` 是否可用
- 外部 shell 是否能成功跑一次可清理的 `cmux new-workspace` smoke test

验证结果：✓ = 通过 / ✗ = 失败 / → = 跳过（正常）

如需强制重新部署所有配置：

```bash
bash setup/bootstrap.sh --force
```

## 开发状态

- [x] Ghostty 配置同步完成
- [x] Cmux + Zed 集成方案完成
- [x] Brewfile 备份完成
- [x] Starship / Zsh / Zed 真实配置同步
- [x] Homebrew Tap 安装方式完成
- [ ] Cmux workspace 模板配置
- [ ] Zed MCP Server 完整配置
- [ ] 跨设备验证

## 参考

- [Cmux 官网](https://cmux.com/) · [GitHub](https://github.com/manaflow-ai/cmux)
- [Zed 编辑器](https://zed.dev/) · [Ghostty 扩展](https://zed.dev/extensions/ghostty)
- [Ghostty 官方文档](https://ghostty.org/docs)
- [BetterStack Cmux 指南](https://betterstack.com/community/guides/ai/cmux-terminal/)
