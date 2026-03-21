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
**Description**: Ghostty 终端模拟器性能优化项目，包含基准测试、配置优化和迭代记录

## Directory Structure

| Path | Purpose |
|------|---------|
| `.project.yaml` | Project metadata |
| `.context/state.yaml` | Session state and working memory |
| `.context/conversations/` | Session records (auto-generated) |
| `knowledge/` | Persistent knowledge documents |
| `tasks/` | Task tracking |
| `artifacts/` | Outputs and deliverables |
