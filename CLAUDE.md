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

## Project DNA

**一句话定位**: Ghostty 终端模拟器性能优化项目，包含基准测试、配置优化和迭代记录

**核心设计原则**: (待补充 — 在项目推进中逐步完善)

**技术栈**: (待补充)

---

## Current State

<!-- AGENT_CONTEXT_START -->
**Last Updated**: 2026-03-21T04:14:33.962Z

**Current Task**: No active task (status: unknown)

**Active Items**:
- Define project goals
- Set up initial tasks


**Next Action**: Define project goals
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
