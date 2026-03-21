# AI Agent 多协作编程平台

基于 Ghostty + Cmux + Zed 构建的 AI 多 Agent 协作编程环境。

## 架构

```
┌─────────────────────────────────────────────────┐
│  Cmux (AI 指挥中心)                              │
│  ┌──────────┬──────────┬──────────┐             │
│  │ Claude   │ Codex    │ Browser  │  ← 分屏     │
│  │ Code     │          │ (内置)   │             │
│  ├──────────┴──────────┴──────────┤             │
│  │       libghostty 渲染引擎       │  ← GPU 加速 │
│  │     读取 ~/.config/ghostty/config│             │
│  └────────────────────────────────┘             │
├─────────────────────────────────────────────────┤
│  Zed (代码编辑器)                                │
│  · 文件浏览/编辑  · AI Agent Panel  · MCP 集成   │
├─────────────────────────────────────────────────┤
│  Ghostty (独立终端 / 配置基座)                    │
│  · 可单独使用  · 配置被 Cmux 共用  · 快速轻量     │
└─────────────────────────────────────────────────┘
```

## 两种使用模式

### 模式 A: 多 Agent 协作 (Cmux + Zed)
多个 AI Agent 并行编程时使用，Cmux 管理会话，Zed 编辑文件。

### 模式 B: 轻量独立 (Ghostty 单独)
单 Agent 或日常终端操作，直接用 Ghostty，快速轻量。

## 文档导航

| 文档 | 内容 |
|------|------|
| [setup/README.md](setup/README.md) | **快速部署指南** — 新电脑一键初始化 |
| [USER-GUIDE.md](USER-GUIDE.md) | Ghostty 使用指南 |
| [QUICK-REF.md](QUICK-REF.md) | 快捷键速查 |
| [WORKFLOWS.md](WORKFLOWS.md) | 工作流示例 |

### 配置与优化
| 目录 | 内容 |
|------|------|
| `setup/` | 一键部署脚本 + 全部配置模板 |
| `current-config/` | Ghostty 当前配置备份 |
| `optimizations/` | Ghostty 优化方案集合 |

### 参考资料
| 文件 | 内容 |
|------|------|
| `resources/cmux-zed-research.md` | Cmux + Zed 集成研究 |
| `resources/bruceblue-tips.md` | BruceBlue Ghostty 优化建议 |
| `benchmarks/` | 性能测试方法 |

## 快速开始

```bash
# 新电脑初始化 (安装 Cmux + Zed + Ghostty 配置)
bash ~/dev/ghostty-optimization/setup/bootstrap.sh

# 日常使用
# 多 Agent 模式 → 打开 Cmux → 新建 Workspace
# 轻量模式 → 打开 Ghostty
# 编辑文件 → zed .
```

## 已完成
- Ghostty 配置优化 (字体、主题、分屏、Quick Terminal)
- Starship 彩虹状态栏
- fastfetch / btop 监控工具
- BruceBlue 优化建议整合
- Cmux + Zed 集成方案及部署脚本
