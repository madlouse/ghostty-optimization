# Ghostty + Cmux + Zed 集成研究

## 研究日期: 2026-03-21
## 来源: Ben's Bites "How (and what) I'm building this week"

## 核心理念

Ben 的技术栈演进路径：
- 以前: Ghostty 作为终端（快、GPU 加速、macOS 原生）
- 现在: **Cmux 替代 Ghostty**（内置 libghostty，升级为 AI CLI 专用终端）+ **Zed 编辑器**（补齐文件浏览/编辑）

> Cmux 不是 Ghostty 的 fork，是一个独立的原生 macOS 应用，使用 libghostty 做终端渲染。

## 三层架构

| 层级 | 工具 | 职责 |
|------|------|------|
| 终端 | Cmux (内置 libghostty) | AI Agent 会话管理、分屏、通知、内置浏览器 |
| 编辑器 | Zed | 文件浏览/编辑、AI Agent Panel、MCP 集成 |
| 配置 | Ghostty config | Cmux 直接读取 ~/.config/ghostty/config |

## Cmux 核心特性

### 杀手级功能
1. **Agent 通知系统**: 颜色环标识状态（绿=完成、黄=等待输入、红=错误）
2. **垂直标签 sidebar**: 所有会话可视化管理，支持命名
3. **内置浏览器**: WebKit 引擎，不用切出终端就能看网页/测试
4. **Socket API**: `/tmp/cmux.sock`，Agent 可编程控制终端

### 安装方式
```bash
# Homebrew (推荐)
brew tap manaflow-ai/cmux
brew install --cask cmux

# 或下载 .dmg
# 从 cmux.com 或 GitHub releases 下载
```

### CLI 命令
```bash
# Workspace 管理
cmux list-workspaces
cmux new-workspace
cmux rename-workspace

# 分屏
cmux new-split right --workspace workspace:1
cmux new-split down --workspace workspace:1

# 发送命令
cmux send --surface surface:7 "claude"
cmux send-key --surface surface:7 "Return"

# 通知
cmux notify --title "构建完成" --body "测试全部通过"
cmux trigger-flash --surface surface:8

# 浏览器
cmux new-pane --type browser --url https://localhost:3000
cmux browser snapshot --surface surface:2 --interactive

# 读取终端内容
cmux read-screen --surface surface:7
```

### Ghostty 配置兼容
- Cmux 直接读取 `~/.config/ghostty/config`
- 字体、主题、快捷键等全部兼容
- Cmux 特有快捷键在 Settings 中单独配置

## Zed 编辑器

### 为什么选 Zed
- Rust 编写，极速（"快得离谱"）
- 原生 AI Agent Panel（支持 Claude、GPT 等）
- MCP Server 集成
- 文件浏览/编辑弥补 Cmux 的短板

### 安装
```bash
brew install --cask zed
```

### AI 配置
- Agent Panel: 支持 Write/Ask/Minimal 三种模式
- 支持 Anthropic、OpenAI、Google、Ollama 等多模型
- ACP (Agent Client Protocol) 集成外部 Agent

## 实际工作流

1. **Cmux** 作为 AI 指挥中心：
   - 每个项目一个 Workspace
   - 多个 Claude Code / Codex 会话在不同 pane 并行
   - Agent 完成任务 → 通知提醒（不用轮询窗口）
   - 需要看网页/测试 → 内置浏览器分屏

2. **Zed** 作为文件编辑器：
   - 浏览/编辑代码文件
   - 用 Agent Panel 做代码审查或提问
   - MCP Server 扩展工具能力

## 已知限制
- macOS only（无 Linux/Windows）
- 无 session restore（重启不保留会话，不如 tmux）
- 偶尔不稳定（新产品，2026-02 发布）
- 初始配置需约 45 分钟
- 文本选择/滚动还需优化

## 参考来源
- [cmux 官网](https://cmux.com/)
- [cmux GitHub](https://github.com/manaflow-ai/cmux)
- [cmux Review (vibecoding.app)](https://vibecoding.app/blog/cmux-review)
- [cmux 完整指南 (BetterStack)](https://betterstack.com/community/guides/ai/cmux-terminal/)
- [Zed 官网](https://zed.dev/)
- [Zed AI Agent 文档](https://zed.dev/docs/ai/overview)
- [setup-cmux Skill (GitHub Gist)](https://gist.github.com/jbasdf/2f31c6fc12dea4f739543ad41f564c86)
