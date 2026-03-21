# Setup — AI Agent 多协作编程平台部署

## 架构定位

| 组件 | 角色 | 独立可用 |
|------|------|----------|
| **Ghostty** | 终端配置基座，轻量单 Agent 模式 | ✓ |
| **Cmux** | AI 多 Agent 指挥中心 (内置 libghostty) | ✓ |
| **Zed** | 代码编辑器 + AI Agent Panel | ✓ |

关键关系：Cmux 直接读取 `~/.config/ghostty/config`，一份配置两处共用。

## 新电脑初始化

```bash
# 1. 克隆项目
git clone <repo-url> ~/dev/ghostty-optimization

# 2. 预览 (不修改)
bash ~/dev/ghostty-optimization/setup/bootstrap.sh --dry-run

# 3. 执行安装
bash ~/dev/ghostty-optimization/setup/bootstrap.sh
```

## 两种使用模式

### 模式 A: 多 Agent 协作
```bash
# 打开 Cmux → 新建 Workspace → 多个 Agent 并行
cw myproject        # 新建 Workspace
cc                  # 右侧分屏启动 Claude Code
cb                  # 内置浏览器打开 localhost:3000
zed .               # Zed 编辑文件
```

### 模式 B: 轻量独立
```bash
# 打开 Ghostty → 直接使用
claude              # 单 Agent
Cmd+Alt+D           # Ghostty 原生分屏
Ctrl+`              # Quick Terminal
```

## 兼容性

- 已安装的工具 → 跳过
- 已存在的配置 → **不覆盖**
- `.zshrc` → 追加模式（带标记，幂等）
- 修改前 → 自动备份 `~/.config-backup/`

## 文件结构

```
setup/
├── bootstrap.sh                # 一键初始化 (--dry-run 预览)
├── configs/
│   ├── ghostty-config          # Ghostty 配置 (Cmux 共用)
│   ├── zed-settings.json       # Zed 编辑器配置
│   ├── cmux-notify-hook.sh     # Claude Code → Cmux 通知
│   └── zshrc-append            # Shell 快捷函数
└── backup-snapshot/            # 当前机器配置快照 (已脱敏)
```

## 快捷命令

| 命令 | 功能 |
|------|------|
| `cw name` | 新建 Cmux Workspace |
| `cc` | 右侧分屏启动 Claude Code |
| `cb [url]` | 打开 Cmux 内置浏览器 |
| `z.` | Zed 打开当前目录 |
| `tl` | (兼容) 列出 tmux 会话 |

## 敏感信息

新机器需手动配置：`JONE_AUTH_TOKEN`、`GROK_API_KEY`、代理设置。
