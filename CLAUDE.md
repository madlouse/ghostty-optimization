# CLAUDE.md — ghostty-optimization

## MANDATORY: Recording Protocol

> This is an AgenticOS project. All session activity MUST be recorded.
> Recording is not optional — it is the core function of this system.

### During Session

After completing any meaningful unit of work (feature, fix, design decision, analysis), call `agenticos_record`:

```
agenticos_record({
  summary: "what happened",
  decisions: ["decision 1", ...],
  outcomes: ["outcome 1", ...],
  pending: ["next step 1", ...],
  current_task: { title: "task name", status: "in_progress" }
})
```

### Before Session Ends

When the user signals session end (says goodbye, thanks, done, or stops responding), you MUST:

1. Call `agenticos_record` with a complete session summary
2. Call `agenticos_save` to commit to Git

**If you skip this step, all context from this session is permanently lost.**

---

## Session Start Protocol

When you open this project in a new session, **immediately do the following**:

1. Read the "Current State" section below
2. Greet the user with a brief status report:

```
📍 项目：ghostty-optimization
📌 上次进展：[current_task title + status]
🎯 当前待办：[top pending items]
💡 建议下一步：[recommended next action]

继续上次的工作，还是有新的方向？
```

3. Wait for the user's direction before proceeding

---

## Agent Install Guide

> For instructions on setting up a new machine, **see [AGENTS.md](./AGENTS.md) — New Machine Setup section**.
> Canonical verification checklist: `bash setup/verify.sh`

---

## Project DNA

**一句话定位**: Ghostty + Cmux + Zed AI 多协作编程终端栈 — 配置备份、跨机器恢复、性能优化

**核心设计原则**: 幂等安装（内容一致时自动跳过）、单一事实来源（README.md + verify.sh）、Agent 协作友好

**技术栈**: Shell (bash), bats-core (tests), Homebrew (distribution)

---

## Current State

<!-- AGENT_CONTEXT_START -->
**Last Updated**: 2026-04-03

**Current Task**: Issue #10 — AGENTS.md 引用不存在的 AgenticOS 文件（进行中）

**Active Items**:
- Issue #6: brew bundle 错误处理 → PR #12 已合并
- Issue #10: AGENTS.md / CLAUDE.md 文档清理 → 进行中
- Issue #9: bootstrap 配置 cmux socket automation mode → 待处理
- Issue #7: Brewfile 拆分（core vs personal）→ 待处理
- Issue #5: 可重现性（阻塞于 #7, #9, #10）
- Issue #8: README vs bootstrap.sh 行为不符 → 待处理

**Next Action**: 完成 #10 后继续 #9
<!-- AGENT_CONTEXT_END -->

---

## Navigation

| 目录/文件 | 用途 |
|-----------|------|
| `.project.yaml` | 项目元信息（AgenticOS MCP 创建）|
| `.context/state.yaml` | 当前会话状态（AgenticOS MCP 维护）|
| `.context/conversations/` | 会话记录（AgenticOS MCP 创建）|
| `setup/bootstrap.sh` | 幂等初始化脚本 |
| `setup/verify.sh` | 统一验证 checklist（Canonical）|
| `AGENTS.md` | Codex/Cursor Agent 安装指引 |
| `README.md` | 人类入口文档（安装 guide 单一来源）|
