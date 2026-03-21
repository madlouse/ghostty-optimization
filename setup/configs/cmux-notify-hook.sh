#!/usr/bin/env bash
# Cmux 通知 Hook — Claude Code 任务完成时触发
# 用法: 在 Claude Code settings.json 的 hooks 中配置

# 检查 cmux 是否可用
if ! command -v cmux &>/dev/null; then
    exit 0
fi

# 从环境变量获取事件信息
EVENT="${CLAUDE_EVENT:-unknown}"
TASK="${CLAUDE_TASK:-}"

case "$EVENT" in
    "task_complete")
        cmux notify --title "Claude Code" --body "任务完成: ${TASK:-done}"
        ;;
    "error")
        cmux notify --title "Claude Code" --body "出错: ${TASK:-error}"
        ;;
    "waiting")
        cmux notify --title "Claude Code" --body "等待输入"
        ;;
esac
