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
**Last Updated**: 2026-04-02

**Current Task**: Issue #4 — 文档 + formula 修复（进行中）

**Active Items**:
- bootstrap.sh 幂等性改造（已实现 diff 检查 + 标记文件）
- 创建 `setup/verify.sh` 作为统一验证脚本
- 更新 CLAUDE.md / AGENTS.md 文档引用关系

**Next Action**: 完成 verify.sh + 文档引用后提交
<!-- AGENT_CONTEXT_END -->

---

## Navigation

| 目录/文件 | 用途 |
|-----------|------|
| `.project.yaml` | 项目元信息 |
| `.context/state.yaml` | 当前会话状态及工作记忆 |
| `.context/conversations/` | 会话记录（自动生成） |
| `knowledge/` | 持久化知识文档 |
| `tasks/` | 任务追踪 |
| `artifacts/` | 产出物 |
| `setup/bootstrap.sh` | 幂等初始化脚本 |
| `setup/verify.sh` | 统一验证 checklist（Canonical）|
| `AGENTS.md` | Codex/Cursor Agent 安装指引 |
| `README.md` | 人类入口文档（安装 guide 单一来源）|
