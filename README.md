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

## 两种使用模式

### 模式 A: 多 Agent 协作 (Cmux + Zed)

多个 AI Agent 并行编程时使用。

```bash
# Cmux: 新建 Workspace，按项目组织会话
cw myproject     # 创建 Workspace

# Cmux: 分屏启动 Agent
cc               # 右侧分屏 + 启动 Claude Code

# Cmux: 内置浏览器看文档
cb https://docs.example.com

# Zed: 编辑文件
zed file.py     # 打开文件
z.              # 打开当前目录
```

### 模式 B: 轻量独立 (Ghostty)

单 Agent 或日常终端操作，快速启动。

```bash
claude           # 启动 Claude Code
Cmd+Alt+D        # Ghostty 原生分屏
Ctrl+`           # Quick Terminal (全局呼出)
```

## 一键安装

```bash
# 新电脑，一行命令搞定
brew tap madlouse/ghostty https://github.com/madlouse/homebrew-ghostty
brew install ghostty-cmux
```

## 文件结构

```
ghostty-optimization/
├── setup/
│   ├── bootstrap.sh          # 初始化脚本 (Homebrew 自动调用)
│   └── configs/
│       ├── ghostty-config    # Ghostty 配置 (Cmux 共用)
│       ├── zed-settings.json # Zed 配置
│       └── cmux-notify-hook.sh  # Agent 通知 Hook
├── optimizations/            # Ghostty 性能 / UX / 主题优化
├── resources/               # 研究文档 (Cmux/Zed/Ghostty)
└── benchmarks/              # 性能测试方法
```

## 配置兼容性

| 工具 | 配置路径 | 来源 |
|------|----------|------|
| Ghostty | `~/.config/ghostty/config` | 本仓库 `setup/configs/ghostty-config` |
| Cmux | 同上 (libghostty 读取) | 同上 |
| Zed | `~/.config/zed/settings.json` | 本仓库 `setup/configs/zed-settings.json` |
| Starship | `~/.config/starship.toml` | 保留已有 / 需单独配置 |
| Shell | `~/.zshrc` | 追加模式，不覆盖已有 |

## 开发状态

- [x] Ghostty 配置优化完成
- [x] Cmux + Zed 集成方案完成
- [x] 一键部署脚本完成
- [x] Homebrew Tap 安装方式完成
- [ ] Cmux workspace 模板配置
- [ ] Zed MCP Server 完整配置
- [ ] 跨设备验证

## 参考

- [Cmux 官网](https://cmux.com/) · [GitHub](https://github.com/manaflow-ai/cmux)
- [Zed 编辑器](https://zed.dev/) · [Ghostty 扩展](https://zed.dev/extensions/ghostty)
- [Ghostty 官方文档](https://ghostty.org/docs)
- [BetterStack Cmux 指南](https://betterstack.com/community/guides/ai/cmux-terminal/)
