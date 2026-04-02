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
```

或手动运行（直接克隆本仓库）：

```bash
git clone https://github.com/madlouse/ghostty-optimization.git ~/dev/ghostty-optimization
cd ~/dev/ghostty-optimization
bash setup/bootstrap.sh
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
cw myproject              # 新建 Workspace
cc                        # 右侧分屏 + 启动 Claude Code
cb https://docs.example.com  # 内置浏览器

zed .                     # 打开当前目录
zed file.py               # 打开文件
```

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
| Starship | `~/.config/starship.toml` | `setup/backup/starship.toml` | 覆盖（旧版备份）|
| Zed | `~/.config/zed/settings.json` | `setup/backup/zed/settings.json` | 覆盖（旧版备份）|
| Shell | `~/.zshrc` | `setup/backup/zshrc` | **全量覆盖**（旧版备份至 `~/.config-backup/`）|
| API Keys | `~/.env.local` | `setup/backup/env.local.example` | 仅首次创建，不覆盖 |
| 本机专属 | `~/.zshrc.local` | `setup/backup/zshrc.local.example` | 仅首次创建，不覆盖 |

> ⚠️ **注意**: `.zshrc` 采用全量覆盖，安装前请将自定义内容迁移到 `~/.zshrc.local`。

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

之后在新电脑上 `brew upgrade ghostty-cmux` 即可拉取最新配置。

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
